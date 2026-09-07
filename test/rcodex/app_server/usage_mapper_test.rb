# frozen_string_literal: true

require "test_helper"

class UsageMapperTest < Minitest::Test
  def test_maps_primary_and_secondary_by_window_duration_not_by_slot
    result = {
      "rateLimits" => {
        "limitId" => "codex", "planType" => "plus",
        "primary" => { "usedPercent" => 10, "windowDurationMins" => 300, "resetsAt" => 1_788_757_140 },
        "secondary" => { "usedPercent" => 20, "windowDurationMins" => 10_080, "resetsAt" => 1_789_254_862 }
      }
    }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: nil, codex_version: nil)

    assert_equal "5h", snapshot.five_hour_window.kind
    assert_equal "weekly", snapshot.weekly_window.kind
    assert_equal 10, snapshot.five_hour_window.used_percent
  end

  def test_classifies_an_unknown_window_duration_by_days_or_hours
    result = { "rateLimits" => { "primary" => { "usedPercent" => 1, "windowDurationMins" => 1440 } } }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: nil, codex_version: nil)
    assert_equal "1d", snapshot.ordered_windows.first.kind
  end

  def test_tolerates_a_missing_window_without_raising
    result = { "rateLimits" => { "primary" => nil, "secondary" => nil } }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: nil, codex_version: nil)
    assert_empty snapshot.ordered_windows
  end

  # windowDurationMins is how we tell a "weekly" bucket from a "5h" one —
  # without it, a window falls back to its slot name rather than being
  # mislabeled. This is intentional, not a gap: a bucket without a
  # duration still shows up via ordered_windows, just uncategorized.
  def test_a_window_without_a_duration_falls_back_to_its_slot_name_instead_of_being_dropped
    result = { "rateLimits" => { "secondary" => { "usedPercent" => 5 } } }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: nil, codex_version: nil)
    assert_nil snapshot.five_hour_window
    assert_nil snapshot.weekly_window
    assert_equal %w[secondary], snapshot.ordered_windows.map(&:kind)
  end

  def test_falls_back_to_account_plan_type_when_snapshot_omits_it
    result = { "rateLimits" => {} }
    account = { "account" => { "type" => "chatgpt", "email" => "a@b.com", "planType" => "pro" } }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: account, codex_version: nil)
    assert_equal "pro", snapshot.plan_type
    assert_equal "a@b.com", snapshot.account.email
  end

  def test_other_buckets_excludes_the_primary_limit_id
    result = {
      "rateLimits" => { "limitId" => "codex" },
      "rateLimitsByLimitId" => { "codex" => {}, "extra" => {} }
    }
    snapshot = RCodex::AppServer::UsageMapper.build(rate_limits_result: result, account_result: nil, codex_version: nil)
    assert_equal %w[extra], snapshot.other_buckets
  end
end
