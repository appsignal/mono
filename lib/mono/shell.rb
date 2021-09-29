# frozen_string_literal: true

module Mono
  module Shell
    module_function

    def ask_for_input
      value = $stdin.gets
      value ? value.chomp : ""
    rescue Interrupt
      puts "\nExiting..."
      exit 1
    end

    def required_input(prompt)
      loop do
        print prompt
        value = ask_for_input
        return value unless value.empty?
      end
    end

    def yes_or_no(prompt, options = {})
      loop do
        print prompt
        input = ask_for_input.strip
        input = options[:default] if input.empty? && options[:default]
        case input
        when "y", "Y", "yes"
          return true
        when "n", "N", "no"
          return false
        end
      end
    end
  end
end
