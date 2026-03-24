require "test_helper"

class SimeparClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:simepar)
    @client = SimeparClient.new(@data_source)
  end

  test "call returns empty array (stub implementation)" do
    result = @client.call

    assert_equal [], result
  end
end
