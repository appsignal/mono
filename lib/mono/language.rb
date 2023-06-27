# frozen_string_literal: true

module Mono
  class UnknownLanguageError < Mono::Error
    def initialize(language)
      @language = language
      super()
    end

    def message
      "Unknown language configured: `#{@language}`. " \
        "Please configure `mono.yml` with a `language`."
    end
  end

  module Language
    def self.for(language)
      case language
      when "nodejs"
        Languages::Nodejs::Language
      when "elixir"
        Languages::Elixir::Language
      when "ruby"
        Languages::Ruby::Language
      when "custom"
        Languages::Custom::Language
      when "git"
        Languages::Git::Language
      else
        raise UnknownLanguageError, language
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
