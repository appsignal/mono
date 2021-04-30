# frozen_string_literal: true

module Mono
  class Error < StandardError; end
end

require "mono/version"
require "mono/config"
require "mono/command"
require "mono/changeset"
require "mono/changeset_collection"
require "mono/package"
require "mono/languages"
