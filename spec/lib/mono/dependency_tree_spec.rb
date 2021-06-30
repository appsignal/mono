# frozen_string_literal: true

RSpec.describe Mono::DependencyTree do
  describe "#packages" do
    let(:config) { mono_config }

    it "returns packages in dependency order" do
      prepare_new_project do
        create_package "types" do
          create_package_json :version => "1.0.0"
        end
        create_package "nodejs-ext" do
          create_package_json :version => "1.2.3"
        end
        create_package "nodejs" do
          create_package_json :version => "2.0.0",
            :dependencies => {
              "nodejs-ext" => "=1.2.3",
              "types" => "=1.0.0"
            }
        end
        create_package "apollo" do
          create_package_json :version => "2.0.0",
            :dependencies => {
              "nodejs" => "=2.0.0",
              "types" => "=1.0.0"
            }
        end
        create_package "apollo-addon" do
          create_package_json :version => "2.0.0",
            :dependencies => {
              "apollo" => "=2.0.0"
            }
        end
      end

      package_types = nodejs_package("types")
      package_ext = nodejs_package("nodejs-ext")
      package_node = nodejs_package("nodejs")
      package_apollo = nodejs_package("apollo")
      package_apollo_addon = nodejs_package("apollo-addon")
      promoter = described_class.new([
        package_apollo_addon,
        package_apollo,
        package_node,
        package_ext,
        package_types
      ])
      expect(promoter.packages).to eql([
        package_ext,
        package_types,
        package_node,
        package_apollo,
        package_apollo_addon
      ])
    end

    context "with infinite loop of dependencies" do
      it "raises an error if there's a circular dependency loop" do
        prepare_new_project do
          create_package "a" do
            create_package_json :version => "1.0.1", :dependencies => { "c" => "1.0.3" }
          end
          create_package "b" do
            create_package_json :version => "1.0.2", :dependencies => { "a" => "1.0.1" }
          end
          create_package "c" do
            create_package_json :version => "1.0.3", :dependencies => { "b" => "1.0.2" }
          end
        end

        package_a = nodejs_package("a")
        package_b = nodejs_package("b")
        package_c = nodejs_package("c")
        promoter = described_class.new([package_a, package_b, package_c])
        expect { promoter.packages }.to raise_error(Mono::CircularDependencyError)
      end
    end
  end

  def nodejs_package(path)
    Mono::Languages::Nodejs::Package.new(nil, package_path(path), config)
  end
end
