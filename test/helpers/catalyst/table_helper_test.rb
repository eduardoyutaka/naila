require "test_helper"

class Catalyst::TableHelperTest < ActionView::TestCase
  include Catalyst::TableHelper

  test "catalyst_table renders table structure" do
    html = catalyst_table { tag.tr { tag.td("Hello") } }
    assert_match %r{<table\b}, html
    assert_match /min-w-full/, html
    assert_match /Hello/, html
  end

  test "catalyst_table_head renders thead with muted text" do
    html = catalyst_table_head { tag.tr { tag.th("Name") } }
    assert_match %r{<thead\b}, html
    assert_match /text-zinc-500/, html
  end

  test "catalyst_th renders with border and font-medium" do
    html = catalyst_table { catalyst_th("Name") }
    assert_match /font-medium/, html
    assert_match /border-b/, html
  end

  test "catalyst_td renders with padding" do
    html = catalyst_table { catalyst_td("Value") }
    assert_match /px-4/, html
    assert_match /Value/, html
  end

  test "catalyst_td respects dense option" do
    html = catalyst_table(dense: true) { catalyst_td("X") }
    assert_match /py-2\.5/, html
  end

  test "catalyst_table_row with striped option" do
    html = catalyst_table(striped: true) { catalyst_table_row { catalyst_td("X") } }
    assert_match /even:bg-zinc-950\/2\.5/, html
  end
end
