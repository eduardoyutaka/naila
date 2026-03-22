ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  private

  def sign_in_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
    follow_redirect!
  end
end
