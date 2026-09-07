# frozen_string_literal: true

require "test_helper"

class UsageSnapshotTest < Minitest::Test
  def build(windows:, other_buckets: [])
    RCodex::Domain::UsageSnapshot.new(
      account: nil, plan_type: "plus", limit_id: "codex", limit_name: nil,
      windows: windows, credits: nil, rate_limit_reached_type: nil,
      spend_control_reached: false, individual_limit: nil,
      ordinary_usage_allowed: nil, reset_credits_available: 0,
      other_buckets: other_buckets, codex_version: "test", fetched_at: Time.now
    )
  end

  def five_hour
    RCodex::Domain::RateLimitWindow.new(slot: "primary", kind: "5h", label: "5-hour",
                                         window_minutes: 300, used_percent: 1, resets_at: nil)
  end

  def weekly
    RCodex::Domain::RateLimitWindow.new(slot: "secondary", kind: "weekly", label: "weekly",
                                         window_minutes: 10_080, used_percent: 2, resets_at: nil)
  end

  def test_ordered_windows_puts_5h_before_weekly_regardless_of_insertion_order
    snapshot = build(windows: { "weekly" => weekly, "5h" => five_hour })
    assert_equal %w[5h weekly], snapshot.ordered_windows.map(&:kind)
  end

  def test_ordered_windows_appends_unknown_buckets_after_the_canonical_two
    monthly = RCodex::Domain::RateLimitWindow.new(slot: "tertiary", kind: "30d", label: "30d",
                                                   window_minutes: 43_200, used_percent: 3, resets_at: nil)
    snapshot = build(windows: { "5h" => five_hour, "weekly" => weekly, "30d" => monthly })
    assert_equal %w[5h weekly 30d], snapshot.ordered_windows.map(&:kind)
  end

  def test_ordered_windows_tolerates_a_missing_window
    snapshot = build(windows: { "weekly" => weekly })
    assert_equal %w[weekly], snapshot.ordered_windows.map(&:kind)
  end

  def test_reset_credits_available_predicate
    positive = RCodex::Domain::UsageSnapshot.new(
      account: nil, plan_type: nil, limit_id: nil, limit_name: nil, windows: {},
      credits: nil, rate_limit_reached_type: nil, spend_control_reached: false,
      individual_limit: nil, ordinary_usage_allowed: nil, reset_credits_available: 2,
      other_buckets: [], codex_version: nil, fetched_at: Time.now
    )
    assert positive.reset_credits_available?
    refute build(windows: {}, other_buckets: []).reset_credits_available? # 0 credits => false
  end

  def test_to_h_round_trips_windows_and_flags
    snapshot = build(windows: { "5h" => five_hour }, other_buckets: %w[extra])
    hash = snapshot.to_h
    assert_equal "plus", hash["plan_type"]
    assert_equal %w[extra], hash["other_buckets"]
    assert hash["windows"].key?("5h")
  end
end
