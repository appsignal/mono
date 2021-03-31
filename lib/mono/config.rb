# frozen_string_literal: true

require "yaml"

module Mono
  class Config
    def initialize
      @config = YAML.safe_load(File.read("mono.yml"))
    end

    def language
      @config.fetch("language") { raise "No language configured." }
    end

    def repo
      @config.fetch("repo") { raise "No `repo` configured in mono.yml." }
    end

    def packages_dir
      @config["packages_dir"]
    end

    def monorepo?
      @config.key?("packages_dir")
    end

    def command?(cmd)
      @config.fetch(cmd, {}).key?("command")
    end

    def command(cmd)
      @config.fetch(cmd, {}).fetch("command") do
        raise "Command '#{cmd}.command' not found."
      end
    end

    def hooks(command, type)
      Array(@config.fetch(command, {}).fetch(type, []))
    end

    def publish
      @config["publish"]
    end

    def config?(key)
      @config.key?(key)
    end

    def config(key)
      @config.fetch(key) { raise "No config found for key '#{key}'" }
    end
  end
end
