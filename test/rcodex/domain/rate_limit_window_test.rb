# frozen_string_literal: true

require "test_helper"

class RateLimitWindowTest < Minitest::Test
  def window(used_percent:, resets_at: nil)
    RCodex::Domain::RateLimitWindow.new(
      slot: "primary", kind: "5h", label: "5-hour",
      window_minutes: 300, used_percent: used_percent, resets_at: resets_at
    )
  end

  def test_remaining_percent_is_the_complement_of_used_percent
    assert_equal 70, window(used_percent: 30).remaining_percent
  end

  def test_severity_thresholds
    assert_equal :ok, window(used_percent: 59).severity
    assert_equal :warning, window(used_percent: 60).severity
    assert_equal :warning, window(used_percent: 84).severity
    assert_equal :critical, window(used_percent: 85).severity
    assert_equal :critical, window(used_percent: 100).severity
  end

  def test_resets_in_seconds_never_goes_negative_after_reset_time_passes
    past = Time.now - 10
    assert_equal 0, window(used_percent: 10, resets_at: past).resets_in_seconds
  end

  def test_resets_in_seconds_is_nil_without_a_reset_time
    assert_nil window(used_percent: 10).resets_in_seconds
  end

  def test_to_h_uses_iso8601_and_unix_seconds
    at = Time.at(1_788_757_140)
    hash = window(used_percent: 5, resets_at: at).to_h
    assert_equal 1_788_757_140, hash["resets_at_unix"]
    assert_equal at.iso8601, hash["resets_at"]
  end
end
