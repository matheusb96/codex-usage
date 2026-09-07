# frozen_string_literal: true

module RCodex
  module Domain
    # Aggregate root for one `account/rateLimits/read` read: the account,
    # its plan, every known usage window, credits, and backend flags.
    # Built only by RCodex::AppServer::UsageMapper — the domain itself
    # never touches raw JSON.
    class UsageSnapshot
      CANONICAL_ORDER = %w[5h weekly].freeze

      attr_reader :account, :plan_type, :limit_id, :limit_name, :credits,
                  :rate_limit_reached_type, :spend_control_reached, :individual_limit,
                  :ordinary_usage_allowed, :reset_credits_available, :other_buckets,
                  :codex_version, :fetched_at

      # @param windows [Hash{String => RateLimitWindow}] keyed by window kind ("5h", "weekly", ...)
      def initialize(account:, plan_type:, limit_id:, limit_name:, windows:, credits:,
                     rate_limit_reached_type:, spend_control_reached:, individual_limit:,
                     ordinary_usage_allowed:, reset_credits_available:, other_buckets:,
                     codex_version:, fetched_at:)
        @account = account
        @plan_type = plan_type
        @limit_id = limit_id
        @limit_name = limit_name
        @windows = windows
        @credits = credits
        @rate_limit_reached_type = rate_limit_reached_type
        @spend_control_reached = spend_control_reached
        @individual_limit = individual_limit
        @ordinary_usage_allowed = ordinary_usage_allowed
        @reset_credits_available = reset_credits_available
        @other_buckets = other_buckets
        @codex_version = codex_version
        @fetched_at = fetched_at
      end

      def five_hour_window
        @windows["5h"]
      end

      def weekly_window
        @windows["weekly"]
      end

      # 5-hour and weekly first (when present), then anything else the
      # backend reports, in a stable order.
      def ordered_windows
        known = CANONICAL_ORDER.map { |kind| @windows[kind] }.compact
        rest = @windows.reject { |kind, _| CANONICAL_ORDER.include?(kind) }.values
        known + rest
      end

      def credits?
        !credits.nil?
      end

      def spend_control_reached?
        spend_control_reached == true
      end

      def reset_credits_available?
        reset_credits_available.is_a?(Integer) && reset_credits_available.positive?
      end

      def other_buckets?
        !other_buckets.empty?
      end

      def to_h
        {
          "ok" => true,
          "fetched_at" => fetched_at.iso8601,
          "codex_version" => codex_version,
          "account_type" => account&.type,
          "email" => account&.email,
          "plan_type" => plan_type,
          "limit_id" => limit_id,
          "limit_name" => limit_name,
          "windows" => @windows.transform_values(&:to_h),
          "credits" => credits&.to_h,
          "rate_limit_reached_type" => rate_limit_reached_type,
          "spend_control_reached" => spend_control_reached,
          "individual_limit" => individual_limit,
          "ordinary_usage_allowed" => ordinary_usage_allowed,
          "reset_credits_available" => reset_credits_available,
          "other_buckets" => other_buckets
        }
      end
    end
  end
end
