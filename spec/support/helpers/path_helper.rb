# frozen_string_literal: true

module PathHelper
  def in_elixir_single_project(&block)
    Dir.chdir("spec/support/examples/elixir_single_project", &block)
  end

  def in_elixir_mono_project(&block)
    Dir.chdir("spec/support/examples/elixir_mono_project", &block)
  end

  def in_nodejs_single_project(client = :npm, &block)
    Dir.chdir("spec/support/examples/nodejs_#{client}_single_project", &block)
  end

  def in_nodejs_mono_project(client = :npm, &block)
    Dir.chdir("spec/support/examples/nodejs_#{client}_mono_project", &block)
  end

  def in_ruby_single_project(&block)
    Dir.chdir("spec/support/examples/ruby_single_project", &block)
  end

  def in_ruby_mono_project(&block)
    Dir.chdir("spec/support/examples/ruby_mono_project", &block)
  end
end
