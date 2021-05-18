# frozen_string_literal: true

module Mono
  class Error < StandardError; end

  class NoSuchCommandError < Error
    def initialize(command)
      @command = command
      super()
    end

    def message
      "No such command found `#{@command}`"
    end
  end
end

require "mono/version_object"
require "mono/version_promoter"
require "mono/config"
require "mono/command"
require "mono/changeset"
require "mono/changeset_collection"
require "mono/package"
require "mono/languages"
