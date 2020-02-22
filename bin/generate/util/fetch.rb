# frozen_string_literal: true

require 'net/http'
require_relative '../../../lib/spellr/string_format'

module Fetch
  extend Spellr::StringFormat

  module_function

  def fetch(uri_str, uri_proc: URI.method(:parse), limit: 10) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    sleep 0.5
    if limit == 0
      warn red("#{uri_str} was the last in an HTTP redirect chain that was too long")
      ''
    end

    response = Net::HTTP.get_response(uri_proc.call(uri_str))
    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      fetch(uri_proc.call(response['location']), limit: limit - 1, uri_proc: uri_proc)
    else
      warn red("#{uri_str} #{response.code}") if limit == 0
      ''
    end
  rescue StandardError => e
    warn red("#{uri_str} #{e}")
    ''
  end
end
