# frozen_string_literal: true

module RCodex
  module AppServer
    # Anti-corruption layer: turns the raw account/read + account/rateLimits/read
    # hashes into a RCodex::Domain::UsageSnapshot. All knowledge of the backend's
    # JSON field names and window-duration conventions lives here, not in the
    # domain objects themselves.
    module UsageMapper
      FIVE_HOUR_MINUTES = 300
      WEEKLY_MINUTES = 10_080

      module_function

      def build(rate_limits_result:, account_result:, codex_version:, now: Time.now)
        snapshot = rate_limits_result.fetch("rateLimits", {})
        account_hash = account_result && account_result["account"]

        windows = build_windows(snapshot)
        other_buckets = (rate_limits_result["rateLimitsByLimitId"] || {}).keys - [snapshot["limitId"]].compact

        Domain::UsageSnapshot.new(
          account: map_account(account_hash),
          plan_type: snapshot["planType"] || account_hash&.fetch("planType", nil),
          limit_id: snapshot["limitId"],
          limit_name: snapshot["limitName"],
          windows: windows,
          credits: map_credits(snapshot["credits"]),
          rate_limit_reached_type: snapshot["rateLimitReachedType"],
          spend_control_reached: snapshot["spendControlReached"],
          individual_limit: snapshot["individualLimit"],
          ordinary_usage_allowed: rate_limits_result["ordinaryUsageAllowed"],
          reset_credits_available: rate_limits_result.dig("rateLimitResetCredits", "availableCount"),
          other_buckets: other_buckets,
          codex_version: codex_version,
          fetched_at: now
        )
      end

      def build_windows(snapshot)
        windows = {}
        [["primary", snapshot["primary"]], ["secondary", snapshot["secondary"]]].each do |slot, raw|
          window = map_window(slot, raw)
          next unless window

          key = windows.key?(window.kind) ? slot : window.kind
          windows[key] = window
        end
        windows
      end

      def map_window(slot, raw)
        return nil unless raw.is_a?(Hash)

        kind = classify(raw["windowDurationMins"]) || slot
        Domain::RateLimitWindow.new(
          slot: slot,
          kind: kind,
          label: label_for(kind),
          window_minutes: raw["windowDurationMins"],
          used_percent: raw["usedPercent"].to_i.clamp(0, 100),
          resets_at: raw["resetsAt"] && Time.at(raw["resetsAt"]).localtime
        )
      end

      def classify(minutes)
        case minutes
        when nil then nil
        when FIVE_HOUR_MINUTES then "5h"
        when WEEKLY_MINUTES then "weekly"
        else
          if (minutes % 1440).zero? then "#{minutes / 1440}d"
          elsif (minutes % 60).zero? then "#{minutes / 60}h"
          else "#{minutes}m"
          end
        end
      end

      def label_for(kind)
        case kind
        when "5h" then "5-hour"
        when "weekly" then "weekly"
        else kind
        end
      end

      def map_account(hash)
        return nil unless hash

        Domain::Account.new(type: hash["type"], email: hash["email"], plan_type: hash["planType"])
      end

      def map_credits(hash)
        return nil unless hash

        Domain::CreditsBalance.new(has_credits: hash["hasCredits"], unlimited: hash["unlimited"], balance: hash["balance"])
      end
    end
  end
end
