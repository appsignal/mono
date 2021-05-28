# frozen_string_literal: true

RSpec.describe Mono::Languages::Ruby::Package do
  let(:config) { Mono::Config.new({}) }

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

  def create_package_with_dependencies(path, dependencies)
    prepare_new_project do
      create_package path do
        create_package_gemspec :version => "1.2.3",
          :dependencies => dependencies
      end
    end
  end

  def package_for_path(path)
    described_class.new(nil, package_path(path), config)
  end
end
