require "test_helper"

class Catalyst::ButtonHelperTest < ActionView::TestCase
  include Catalyst::ButtonHelper

  test "catalyst_button renders a button element with solid variant by default" do
    html = catalyst_button("Save")
    assert_match %r{<button\b}, html
    assert_match /font-semibold/, html
    assert_match /Save/, html
  end

  test "catalyst_button with block content" do
    html = catalyst_button { "Click me" }
    assert_match /Click me/, html
  end

  test "catalyst_button_link renders an anchor tag" do
    html = catalyst_button_link("Go", href: "/somewhere")
    assert_match %r{<a\b}, html
    assert_match %r{href="/somewhere"}, html
    assert_match /Go/, html
  end

  test "catalyst_button with outline variant" do
    html = catalyst_button("Cancel", variant: :outline)
    assert_match /border-zinc-950\/10/, html
    assert_no_match /bg-\(--btn-border\)/, html
  end

  test "catalyst_button with plain variant" do
    html = catalyst_button("Cancel", variant: :plain)
    assert_match /border-transparent/, html
  end

  test "catalyst_button with color option" do
    html = catalyst_button("Delete", color: "red")
    assert_match /--btn-bg:var\(--color-red-600\)/, html
  end

  test "catalyst_button includes touch target span" do
    html = catalyst_button("Tap")
    assert_match /pointer-fine:hidden/, html
  end

  test "catalyst_button defaults type to button" do
    html = catalyst_button("Click")
    assert_match /type="button"/, html
  end

  test "catalyst_button_link with sky color for primary action" do
    html = catalyst_button_link("New", href: "/new", color: "sky")
    assert_match /--btn-bg:var\(--color-sky-500\)/, html
  end
end
