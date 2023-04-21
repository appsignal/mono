# frozen_string_literal: true

module Mono
  module Languages
    module Custom
      class Language < Language::Base
        def bootstrap(_options = {})
          # noop
        end

        def unbootstrap(_options = {})
          # noop
        end

        def clean(_options = {})
          # noop
        end
      end
    end
  end
end
