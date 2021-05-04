# frozen_string_literal: true

module Mono
  VERSION = "1.0.0.alpha.1"

  class Error < StandardError; end
end

require "mono/version"
require "mono/version_promoter"
require "mono/config"
require "mono/command"
require "mono/changeset"
require "mono/changeset_collection"
require "mono/package"
require "mono/languages"
