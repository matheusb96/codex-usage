# frozen_string_literal: true

require "test_helper"

class SimplePresenterTest < Minitest::Test
  def test_output_has_no_ansi_escapes_or_bars
    snapshot = RCodex::Domain::UsageSnapshot.new(
      account: nil, plan_type: "plus", limit_id: "codex", limit_name: nil,
      windows: {
        "5h" => RCodex::Domain::RateLimitWindow.new(slot: "primary", kind: "5h", label: "5-hour",
                                                      window_minutes: 300, used_percent: 42, resets_at: nil)
      },
      credits: nil, rate_limit_reached_type: nil, spend_control_reached: false,
      individual_limit: nil, ordinary_usage_allowed: nil, reset_credits_available: 0,
      other_buckets: [], codex_version: "test", fetched_at: Time.now
    )

    out = StringIO.new
    RCodex::Presenters::SimplePresenter.new.render(snapshot, out: out)

    refute_includes out.string, "\e["
    refute_includes out.string, "["
    assert_includes out.string, "5-hour: 42% used"
    assert_includes out.string, "plan:   plus"
  end
end
