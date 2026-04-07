require "test_helper"

class Catalyst::BadgeHelperTest < ActionView::TestCase
  include Catalyst::BadgeHelper

  test "catalyst_badge renders a span with badge classes" do
    html = catalyst_badge("Active")
    assert_match %r{<span\b}, html
    assert_match /rounded-md/, html
    assert_match /Active/, html
  end

  test "catalyst_badge defaults to zinc color" do
    html = catalyst_badge("Status")
    assert_match /bg-zinc-600\/10/, html
  end

  test "catalyst_badge with color option" do
    html = catalyst_badge("Error", color: "red")
    assert_match /bg-red-500\/15/, html
    assert_match /text-red-700/, html
  end

  test "catalyst_badge with block content" do
    html = catalyst_badge(color: "green") { "OK" }
    assert_match /OK/, html
    assert_match /bg-green-500\/15/, html
  end

  test "catalyst_badge with extra class" do
    html = catalyst_badge("X", class: "ml-2")
    assert_match /ml-2/, html
  end
end
