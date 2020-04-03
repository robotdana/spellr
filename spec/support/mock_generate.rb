# frozen_string_literal: true

require 'bundler/setup'
require 'webmock'

include WebMock::API # rubocop:disable Style/MixinUsage # this is the documented way
WebMock.enable!

# stubs to allow generate to not take forever
case File.basename($PROGRAM_NAME)
when 'css', 'html'
  stub_request(:get, %r{\Ahttps://wiki\.developer\.mozilla\.org/.*}).to_return(
    body: <<~HTML
      <a href="https://wiki\.developer\.mozilla\.org/subpage">test</a>
      <code>keyword</code>
    HTML
  )
  stub_request(:get, %r{\Ahttps://wiki\.developer\.mozilla\.org/.*\$json.*}).to_return(
    body: <<~JSON
      { "title": "title", "url": "https://wiki\.developer\.mozilla\.org/whatever" }
    JSON
  )
  stub_request(:get, 'https://www.w3.org/TR/wai-aria/').to_return(body: '')
when 'english'
  stub_request(:get, %r{http://app\.aspell\.net/create?.*}).to_return(
    body: <<~BODY
      LICENSE
      ---
      alpha
      beta
    BODY
  )
when 'ruby'
  class Module
    def constants
      [Array, String, RUBY_VERSION]
    end
  end
end
