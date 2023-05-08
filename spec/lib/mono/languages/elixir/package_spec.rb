# frozen_string_literal: true

RSpec.describe Mono::Languages::Elixir::Package do
  let(:config) { mono_config }

  describe "#current_version" do
    context "with a version set in the project block" do
      it "extracts the current version" do
        package_name = "test_package"
        create_package_with_dependencies package_name, {}

        package = package_for_path(package_name)
        expect(package.current_version).to eql(Mono::Version::Semver.new(1, 2, 3))
      end
    end

    context "with a version set in a module attribute" do
      it "extracts the current version" do
        package_name = "test_package"
        create_package_with_dependencies package_name, {}, true

        package = package_for_path(package_name)
        expect(package.current_version).to eql(Mono::Version::Semver.new(1, 2, 3))
      end
    end
  end

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

  def create_package_with_dependencies(path, dependencies, version_in_module_attribute = false) # rubocop:disable Style/OptionalBooleanParameter
    prepare_new_project do
      create_package path do
        create_package_mix :version => "1.2.3",
          :dependencies => dependencies,
          :version_in_module_attribute? => version_in_module_attribute
      end
    end
  end

  def package_for_path(path)
    described_class.new(nil, package_path(path), config)
  end
end
