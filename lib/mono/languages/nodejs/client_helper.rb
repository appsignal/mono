# frozen_string_literal: true

module Mono
  module Languages
    module Nodejs
      module ClientHelper
        def npm_client
          if config.config?("npm_client")
            config.config("npm_client")
          else
            "npm"
          end
        end
      end
    end
  end
end
