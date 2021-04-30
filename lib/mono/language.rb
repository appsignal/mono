# frozen_string_literal: true

module Mono
  module Language
    def self.for(language)
      case language
      when "nodejs"
        Languages::Nodejs::Language
      when "elixir"
        Languages::Elixir::Language
      when "ruby"
        Languages::Ruby::Language
      else
        raise "Unknown language." \
          "Please configure `mono.yml` with a `language`."
      end
    end

    class Base
      include Command::Helper

      def initialize(config)
        @config = config
      end

      private

      attr_reader :config
    end
  end
end
