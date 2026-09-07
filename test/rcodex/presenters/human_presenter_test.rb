# frozen_string_literal: true

require "test_helper"

class HumanPresenterTest < Minitest::Test
  def setup
    @previous_color_enabled = RCodex::Color.instance_variable_get(:@enabled)
    RCodex::Color.enabled = false
  end

  def teardown
    RCodex::Color.instance_variable_set(:@enabled, @previous_color_enabled)
  end

  def snapshot(spend_control_reached: false, used_percent: 1)
    RCodex::Domain::UsageSnapshot.new(
      account: nil, plan_type: "plus", limit_id: "codex", limit_name: nil,
      windows: {
        "5h" => RCodex::Domain::RateLimitWindow.new(slot: "primary", kind: "5h", label: "5-hour",
                                                      window_minutes: 300, used_percent: used_percent, resets_at: nil)
      },
      credits: nil, rate_limit_reached_type: nil,
      spend_control_reached: spend_control_reached,
      individual_limit: nil, ordinary_usage_allowed: nil, reset_credits_available: 0,
      other_buckets: [], codex_version: "test", fetched_at: Time.now
    )
  end

  def test_renders_plan_and_window_rows
    out = StringIO.new
    RCodex::Presenters::HumanPresenter.new.render(snapshot, out: out)
    assert_includes out.string, "plan:"
    assert_includes out.string, "5-hour:"
    assert_includes out.string, "1% used"
    assert_includes out.string, "reset time n/a"
  end

  def test_omits_optional_rows_when_absent
    out = StringIO.new
    RCodex::Presenters::HumanPresenter.new.render(snapshot(spend_control_reached: false), out: out)
    refute_includes out.string, "spend cap:"
  end

  def test_includes_optional_rows_when_present
    out = StringIO.new
    RCodex::Presenters::HumanPresenter.new.render(snapshot(spend_control_reached: true), out: out)
    assert_includes out.string, "spend cap:"
  end

  def test_render_error_writes_a_plain_message_to_the_given_stream
    out = StringIO.new
    error = RCodex::AppServerError.new("boom", exit_code: 1)
    RCodex::Presenters::HumanPresenter.new.render_error(error, out: out)
    assert_equal "rcodex: boom\n", out.string
  end

  def test_colors_severity_when_enabled
    RCodex::Color.enabled = true
    out = StringIO.new
    RCodex::Presenters::HumanPresenter.new.render(snapshot(used_percent: 99), out: out)
    assert_includes out.string, "\e[31m" # red, for critical severity
  end
end
