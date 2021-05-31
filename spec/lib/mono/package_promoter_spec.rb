# frozen_string_literal: true

RSpec.describe Mono::PackagePromoter do
  describe "#update" do
    let(:config) { Mono::Config.new({}) } # Mock empty config

    it "updates direct dependent packages" do
      prepare_new_project do
        create_package "nodejs-ext" do
          create_package_json :version => "1.2.3"
          add_changeset :patch
        end
        create_package "nodejs" do
          create_package_json :name => "nodejs",
            :version => "2.0.0",
            :dependencies => { "nodejs-ext" => "=1.2.3" }
        end
      end
      package_ext = Mono::Languages::Nodejs::Package.new(nil, package_path("nodejs-ext"), config)
      package_node = Mono::Languages::Nodejs::Package.new(nil, package_path("nodejs"), config)
      promoter = described_class.new([package_ext, package_node])
      expect(promoter.changed_packages).to contain_exactly(
        package_ext,
        package_node
      )
      update_packages(promoter.changed_packages)

      package_ext = Mono::Languages::Nodejs::Package.new(nil, package_path("nodejs-ext"), config)
      expect(package_ext.current_version.to_s).to eql("1.2.4")
      package_node = Mono::Languages::Nodejs::Package.new(nil, package_path("nodejs"), config)
      expect(package_node.current_version.to_s).to eql("2.0.1")
      expect(package_node.dependencies["nodejs-ext"]).to eql("=1.2.4")
    end

    it "updates transient dependent packages" do
      prepare_new_project do
        create_package "core" do
          create_package_json :name => "core", :version => "1.2.3"
          add_changeset :patch
        end
        create_package "plug" do
          create_package_json :name => "plug",
            :version => "2.0.0",
            :dependencies => { "core" => "=1.2.3" }
        end
        create_package "sinatra" do
          create_package_json :name => "sinatra",
            :version => "3.0.0",
            :dependencies => { "plug" => "=2.0.0" }
        end
        create_package "phoenix" do
          create_package_json :name => "phoenix",
            :version => "3.1.0",
            :dependencies => { "plug" => "=2.0.0" }
        end
        create_package "absinthe" do
          create_package_json :name => "absinthe",
            :version => "4.0.0",
            :dependencies => { "phoenix" => "=3.1.0" }
        end
        create_package "no-update" do # Package that does not get updated
          create_package_json :name => "no-update", :version => "5.0.0"
        end
      end
      package_core = nodejs_package("core")
      package_plug = nodejs_package("plug")
      package_phoenix = nodejs_package("phoenix")
      package_sinatra = nodejs_package("sinatra")
      package_absinthe = nodejs_package("absinthe")
      promoter = described_class.new([
        package_core,
        package_plug,
        package_sinatra,
        package_phoenix,
        package_absinthe
      ])
      expect(promoter.changed_packages).to contain_exactly(
        package_core,
        package_plug,
        package_sinatra,
        package_phoenix,
        package_absinthe
      )
      update_packages(promoter.changed_packages)

      package_core = nodejs_package("core")
      expect(package_core.current_version.to_s).to eql("1.2.4")
      package_plug = nodejs_package("plug")
      expect(package_plug.current_version.to_s).to eql("2.0.1")
      expect(package_plug.dependencies["core"]).to eql("=1.2.4")
      package_sinatra = nodejs_package("sinatra")
      expect(package_sinatra.current_version.to_s).to eql("3.0.1")
      expect(package_sinatra.dependencies["plug"]).to eql("=2.0.1")
      package_phoenix = nodejs_package("phoenix")
      expect(package_phoenix.current_version.to_s).to eql("3.1.1")
      expect(package_phoenix.dependencies["plug"]).to eql("=2.0.1")
      package_absinthe = nodejs_package("absinthe")
      expect(package_absinthe.current_version.to_s).to eql("4.0.1")
      expect(package_absinthe.dependencies["phoenix"]).to eql("=3.1.1")
      package_no_update = nodejs_package("no-update")
      expect(package_no_update.current_version.to_s).to eql("5.0.0")
    end

    it "does not update packages without a dependency on updated packages in the project" do
      prepare_new_project do
        create_package "one" do
          create_package_json :name => "one", :version => "1.0.0"
          add_changeset :patch # Mark changes
        end
        create_package "two" do
          create_package_json :name => "two", :version => "2.0.0"
        end
      end
      package_one = nodejs_package("one")
      package_two = nodejs_package("two")
      promoter = described_class.new([package_one, package_two])
      expect(promoter.changed_packages).to contain_exactly(package_one)
      update_packages(promoter.changed_packages)

      package_one = nodejs_package("one")
      expect(package_one.current_version.to_s).to eql("1.0.1") # Changed because of changeset
      package_two = nodejs_package("two")
      expect(package_two.current_version.to_s).to eql("2.0.0") # Unchanged
    end

    context "without changes" do
      it "updates package to final version if it's a prerelease" do
        prepare_new_project do
          create_package "one" do
            create_package_json :name => "one", :version => "1.0.0-rc.7"
          end
        end
        package_one = nodejs_package("one")
        promoter = described_class.new([package_one])
        expect(promoter.changed_packages).to contain_exactly(package_one)
        update_packages(promoter.changed_packages)

        package_one = nodejs_package("one")
        expect(package_one.current_version.to_s).to eql("1.0.0")
      end

      it "updates packages to final version if it's a prerelease" do
        prepare_new_project do
          create_package "a" do
            create_package_json :name => "a", :version => "1.0.0-rc.7"
          end
          create_package "b" do
            create_package_json :name => "b", :version => "2.1.0-rc.10"
          end
          create_package "c" do
            create_package_json :name => "c", :version => "2.1.1-beta.10"
          end
        end
        package_a = nodejs_package("a")
        package_b = nodejs_package("b")
        package_c = nodejs_package("c")
        promoter = described_class.new([package_a, package_b, package_c])
        expect(promoter.changed_packages).to contain_exactly(package_a, package_b, package_c)
        update_packages(promoter.changed_packages)

        package_a = nodejs_package("a")
        expect(package_a.current_version.to_s).to eql("1.0.0")
        package_b = nodejs_package("b")
        expect(package_b.current_version.to_s).to eql("2.1.0")
        package_c = nodejs_package("c")
        expect(package_c.current_version.to_s).to eql("2.1.1")
      end

      it "updates dependent packages if all are a prerelease" do
        prepare_new_project do
          create_package "a" do
            create_package_json :name => "a", :version => "1.0.0-rc.7"
          end
          create_package "b" do
            create_package_json :name => "b", :version => "2.1.0-rc.10",
              :dependencies => { "a" => "1.0.0-rc.7" }
          end
        end
        package_a = nodejs_package("a")
        package_b = nodejs_package("b")
        promoter = described_class.new([package_a, package_b])
        expect(promoter.changed_packages).to contain_exactly(package_a, package_b)
        update_packages(promoter.changed_packages)

        package_a = nodejs_package("a")
        expect(package_a.current_version.to_s).to eql("1.0.0")
        package_b = nodejs_package("b")
        expect(package_b.current_version.to_s).to eql("2.1.0")
      end

      it "updates dependent packages if dependency is a prerelease" do
        prepare_new_project do
          create_package "a" do
            create_package_json :name => "a", :version => "1.0.0-rc.7"
          end
          create_package "b" do
            create_package_json :name => "b", :version => "2.1.0",
              :dependencies => { "a" => "1.0.0-rc.7" }
          end
        end
        package_a = nodejs_package("a")
        package_b = nodejs_package("b")
        promoter = described_class.new([package_a, package_b])
        expect(promoter.changed_packages).to contain_exactly(package_a, package_b)
        update_packages(promoter.changed_packages)

        package_a = nodejs_package("a")
        expect(package_a.current_version.to_s).to eql("1.0.0")
        package_b = nodejs_package("b")
        expect(package_b.current_version.to_s).to eql("2.1.1")
      end
    end
  end

  def nodejs_package(path)
    Mono::Languages::Nodejs::Package.new(nil, package_path(path), config)
  end

  def update_packages(packages)
    packages.each(&:update_spec)
  end
end
