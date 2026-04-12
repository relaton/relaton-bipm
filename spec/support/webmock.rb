require "webmock/rspec"

RSpec.configure do |config|
  config.before do
    WebMock.reset!
    WebMock.disable_net_connect!
  end
end
