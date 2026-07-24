# frozen_string_literal: true

RSpec.describe Mono::Languages::Ruby::Package do
  let(:config) { mono_config }

  describe "#dependencies" do
    context "without dependencies" do
      it "returns empty hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name, {}

        package = package_for_path(package_name)
        expect(package.dependencies).to eql({})
      end
    end

    context "with dependencies" do
      it "returns dependencies hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name,
          "lodash" => "4.17.21",
          "tslib" => "2.2.0",
          "moment" => "2.29.1"

        package = package_for_path(package_name)
        expect(package.dependencies).to eql(
          "lodash" => "4.17.21",
          "tslib" => "2.2.0",
          "moment" => "2.29.1"
        )
      end
    end
  end

  describe "#update_spec" do
    it "rewrites only the dependency line that matches by name" do
      package_name = "test_package"
      prepare_new_project do
        create_package package_name do
          create_ruby_package_files :name => package_name,
            :version => "1.2.3",
            :dependencies => {
              "package_a" => "1.0.0",
              "package_b" => "2.0.0",
              "package_c" => "3.0.0"
            }
          add_changeset :patch
        end
      end

      package = package_for_path(package_name)
      dependency = instance_double(
        described_class,
        :name => "package_b",
        :next_version => "2.1.0"
      )
      package.update_dependency(dependency)
      package.update_spec

      spec_path = File.join(package_path(package_name), "#{package_name}.gemspec")
      contents = File.read(spec_path)
      expect(contents).to include(%(gem.add_dependency "package_a", "1.0.0"))
      expect(contents).to include(%(gem.add_dependency "package_b", "2.1.0"))
      expect(contents).to include(%(gem.add_dependency "package_c", "3.0.0"))
      expect(contents).to_not include(%(gem.add_dependency "package_b", "2.0.0"))
    end

    it "keeps the quote style and skips mismatched quotes" do
      package_name = "test_package"
      prepare_new_project do
        create_package package_name do
          create_ruby_package_files :name => package_name,
            :version => "1.2.3",
            :dependencies => { "double_dep" => "1.0.0" }
          add_changeset :patch
        end
      end

      # Rewrite the gemspec dependency lines to cover both quote styles and a
      # malformed line whose opening and closing quotes do not match.
      spec_path = File.join(package_path(package_name), "#{package_name}.gemspec")
      contents = File.read(spec_path)
      replacement = <<~DEPS.chomp
        gem.add_dependency "double_dep", "1.0.0"
          gem.add_dependency 'single_dep', '2.0.0'
          gem.add_dependency "mismatch_dep", "3.0.0'
      DEPS
      contents = contents.sub(
        %(gem.add_dependency "double_dep", "1.0.0"),
        replacement
      )
      File.write(spec_path, contents)

      package = package_for_path(package_name)
      package.update_dependency(dependency_double("double_dep", "1.1.0"))
      package.update_dependency(dependency_double("single_dep", "2.1.0"))
      package.update_dependency(dependency_double("mismatch_dep", "3.1.0"))
      package.update_spec

      result = File.read(spec_path)
      expect(result).to include(%(gem.add_dependency "double_dep", "1.1.0"))
      expect(result).to include(%(gem.add_dependency 'single_dep', '2.1.0'))
      # The mismatched-quote line is left untouched.
      expect(result).to include(%(gem.add_dependency "mismatch_dep", "3.0.0'))
    end
  end

  def dependency_double(name, next_version)
    instance_double(
      described_class,
      :name => name,
      :next_version => next_version
    )
  end

  def create_package_with_dependencies(path, dependencies)
    prepare_new_project do
      create_package path do
        create_ruby_package_files :version => "1.2.3",
          :dependencies => dependencies
      end
    end
  end

  def package_for_path(path)
    described_class.new(nil, package_path(path), config)
  end
end
