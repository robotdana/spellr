# frozen_string_literal: true

require 'pathname'

module Spellr
  module_function

  def pwd
    @pwd ||= Pathname.pwd
  end

  def pwd_s
    @pwd_s ||= pwd.to_s
  end
end
