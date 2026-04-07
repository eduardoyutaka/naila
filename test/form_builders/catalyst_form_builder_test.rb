require "test_helper"

class CatalystFormBuilderTest < ActionView::TestCase
  setup do
    @user = users(:admin)
  end

  test "text_field wraps input in catalyst span with data-slot=control" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.text_field(:name) }
    assert_match /data-slot="control"/, html
    assert_match /before:absolute/, html
    assert_match /appearance-none rounded-lg/, html
  end

  test "label renders with catalyst styling and data-slot=label" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.label(:name) }
    assert_match /data-slot="label"/, html
    assert_match /font-medium/, html
  end

  test "select wraps in catalyst span with chevron SVG" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f|
      f.select(:role, [["Admin", "admin"]])
    }
    assert_match /data-slot="control"/, html
    assert_match /viewBox/, html  # chevron SVG present
    assert_match /appearance-none/, html
  end

  test "text_area wraps in catalyst span" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.text_area(:name) }
    assert_match /data-slot="control"/, html
    assert_match /resize-y/, html
  end

  test "check_box applies catalyst checkbox classes" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.check_box(:active) }
    assert_match /rounded-\[0\.3125rem\]/, html
  end

  test "field wraps content with spacing classes" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f|
      f.field { f.label(:name) + f.text_field(:name) }
    }
    assert_match /data-slot="label"/, html
    assert_match /data-slot="control"/, html
  end

  test "error_message renders when errors present" do
    @user.errors.add(:name, "can't be blank")
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.error_message(:name) }
    assert_match /text-red-600/, html
    assert_match /can&#39;t be blank/, html
  end

  test "error_message returns nil when no errors" do
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.error_message(:name).to_s }
    assert_no_match /text-red/, html
  end

  test "error_summary renders error list" do
    @user.errors.add(:name, "can't be blank")
    html = form_with(model: @user, url: "/users", builder: CatalystFormBuilder) { |f| f.error_summary }
    assert_match /impediu/, html
    assert_match /can&#39;t be blank/, html
  end
end
