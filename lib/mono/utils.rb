# frozen_string_literal: true

module Mono
  module Utils
    def self.normalize_filename(filename)
      filename.downcase.gsub(/\W/, "-")
    end
  end
end
