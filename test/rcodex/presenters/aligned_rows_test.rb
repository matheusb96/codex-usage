# frozen_string_literal: true

require "test_helper"

class AlignedRowsTest < Minitest::Test
  # This is the actual regression case: a fixed padding width (the
  # original script used a hardcoded %-10s) misaligns as soon as a label
  # is wider than that column. "spend cap" (9 chars) happened to fit the
  # old width exactly, so a longer label is needed to prove this isn't
  # a coincidence — the column must come from the widest label present,
  # however long that turns out to be.
  def test_value_column_matches_the_widest_label_even_when_it_exceeds_any_fixed_width
    rows = RCodex::Presenters::AlignedRows.new
    rows.add("plan", "plus")
    rows.add("a much longer label than any fixed column would expect", "value")

    lines = []
    rows.each_line { |line| lines << line }

    value_column = ->(line) { line.index(/\S/, line.index(":") + 1) }
    assert_equal value_column.call(lines[0]), value_column.call(lines[1])
  end

  def test_gap_controls_spaces_between_colon_and_value
    rows = RCodex::Presenters::AlignedRows.new
    rows.add("a", "1")
    line = nil
    rows.each_line(gap: 3) { |l| line = l }
    assert_equal "a:   1", line
  end

  def test_empty_rows_yield_nothing
    yielded = false
    RCodex::Presenters::AlignedRows.new.each_line { yielded = true }
    refute yielded
  end
end
