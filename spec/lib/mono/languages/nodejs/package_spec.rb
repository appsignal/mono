# frozen_string_literal: true

RSpec.describe Mono::Languages::Nodejs::Package do
  let(:config) { mono_config }

  describe "#dependencies" do
    context "without dependencies" do
      it "returns empty hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name

        package = package_for_path(package_name)
        expect(package.dependencies).to eql({})
      end
    end

    context "with dependencies" do
      it "returns dependencies hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name,
          :dependencies => {
            "lodash" => "4.17.21",
            "tslib" => "2.2.0",
            "moment" => "2.29.1"
          }

        package = package_for_path(package_name)
        expect(package.dependencies).to eql(
          "lodash" => "4.17.21",
          "tslib" => "2.2.0",
          "moment" => "2.29.1"
        )
      end
    end

    context "with optionalDependencies" do
      it "returns dependencies hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name,
          :dependencies => {
            "lodash" => "4.17.21"
          },
          :optionalDependencies => {
            "tslib" => "2.2.1"
          }

        package = package_for_path(package_name)
        expect(package.dependencies).to eql(
          "lodash" => "4.17.21",
          "tslib" => "2.2.1"
        )
      end
    end

    context "with devDependencies" do
      it "returns dependencies hash" do
        package_name = "test_package"
        create_package_with_dependencies package_name,
          :dependencies => {
            "lodash" => "4.17.21"
          },
          :devDependencies => {
            "tslib" => "2.2.2"
          }

        package = package_for_path(package_name)
        expect(package.dependencies).to eql(
          "lodash" => "4.17.21",
          "tslib" => "2.2.2"
        )
      end
    end
  end

  def create_package_with_dependencies(
    path,
    version: "1.2.3",
    **options
  )
    prepare_new_project do
      create_package path do
        create_package_json({ :version => version }.merge(options))
      end
    end
  end

  def package_for_path(path)
    described_class.new(nil, package_path(path), config)
  end
end
