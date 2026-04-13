require "test_helper"

class Catalyst::PaginationHelperTest < ActionView::TestCase
  include Pagy::Frontend
  include Catalyst::PaginationHelper
  include Catalyst::ButtonHelper

  # Stub request for pagy_url_for
  StubRequest = Struct.new(:GET, :base_url, :path, keyword_init: true)

  def request
    @_stub_request ||= StubRequest.new(
      GET: {},
      base_url: "http://test.host",
      path: "/admin/alarms"
    )
  end

  test "catalyst_pagy_nav returns nil for single-page results" do
    pagy = Pagy.new(count: 10, limit: 25, page: 1)
    assert_nil catalyst_pagy_nav(pagy)
  end

  test "catalyst_pagy_nav renders nav for multi-page results" do
    pagy = Pagy.new(count: 100, limit: 25, page: 2)
    html = catalyst_pagy_nav(pagy)

    assert_match /aria-label="Navegação de páginas"/, html
    assert_match /Anterior/, html
    assert_match /Próximo/, html
  end

  test "catalyst_pagy_nav disables previous on first page" do
    pagy = Pagy.new(count: 100, limit: 25, page: 1)
    html = catalyst_pagy_nav(pagy)

    assert_match /disabled.*Anterior/m, html
  end

  test "catalyst_pagy_nav disables next on last page" do
    pagy = Pagy.new(count: 100, limit: 25, page: 4)
    html = catalyst_pagy_nav(pagy)

    assert_match /disabled.*Próximo/m, html
  end

  test "catalyst_pagy_nav highlights current page" do
    pagy = Pagy.new(count: 100, limit: 25, page: 2)
    html = catalyst_pagy_nav(pagy)

    assert_match /aria-current="page"/, html
  end

  test "catalyst_pagy_nav generates correct page URLs with query params" do
    pagy = Pagy.new(count: 100, limit: 25, page: 1)
    html = catalyst_pagy_nav(pagy)

    assert_match %r{page=2}, html
  end
end
