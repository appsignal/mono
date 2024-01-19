# frozen_string_literal: true

RSpec.describe Mono::ChangesetCollection do
  describe "#changesets" do
    let(:test_project) { :nodejs_npm_mono }
    let(:config) { config_for(test_project) }
    let(:package) { package_for("package_one", config) }
    let(:collection) { described_class.new(config, package) }
    let(:changesets) { collection.changesets }
    before { prepare_project test_project }

    context "without changesets" do
      it "returns an empty array" do
        in_project do
          in_package :package_one do
            expect(current_package_changeset_files).to eql([])
          end

          expect(changesets).to eql([])
          expect(collection.any?).to be_falsy
        end
      end
    end

    context "with one changeset" do
      it "returns an array with one changeset object" do
        in_project do
          in_package :package_one do
            add_changeset :patch

            expect(current_package_changeset_files.length).to eql(1)
          end

          expect(changesets.map(&:bump)).to contain_exactly("patch")
          expect(collection.any?).to be_truthy
        end
      end
    end

    context "with multiple changesets" do
      it "returns an array of changeset objects" do
        in_project do
          in_package :package_one do
            add_changeset :patch
            add_changeset :minor
            add_changeset :major

            expect(current_package_changeset_files.length).to eql(3)
          end

          expect(changesets.map(&:bump)).to contain_exactly("patch", "minor", "major")
          expect(collection.any?).to be_truthy
        end
      end
    end
  end

  describe "#next_bump" do
    let(:test_project) { :nodejs_npm_mono }
    let(:config) { config_for(test_project) }
    let(:package) { package_for("package_one", config) }
    let(:collection) { described_class.new(config, package) }
    before { prepare_project test_project }
    subject { collection.next_bump }

    context "with major version" do
      it "returns the major version bump" do
        in_project do
          in_package :package_one do
            add_changeset :patch
            add_changeset :minor
            add_changeset :major
          end

          is_expected.to eql("major")
        end
      end
    end

    context "with minor version" do
      it "returns the major version bump" do
        in_project do
          in_package :package_one do
            add_changeset :patch
            add_changeset :minor
          end

          is_expected.to eql("minor")
        end
      end
    end

    context "with patch version" do
      it "returns the major version bump" do
        in_project do
          in_package :package_one do
            add_changeset :patch
          end

          is_expected.to eql("patch")
        end
      end
    end
  end

  describe "#changesets_by_types_sorted_by_bump" do
    let(:test_project) { :elixir_single }
    let(:config) { config_for(test_project) }
    let(:package) { Mono::Languages::Elixir::Package.new("my-package", ".", config) }
    let(:collection) { described_class.new(config, package) }

    it "returns changesets in a hash per type sorted by version bump" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
        create_changelog
        add_changeset :patch, :type => :fix

        add_changeset :patch, :type => :add
        add_changeset :major, :type => :add
        add_changeset :minor, :type => :add

        add_changeset :patch, :type => :change
        add_changeset :minor, :type => :change
        add_changeset :major, :type => :change

        add_changeset :patch, :type => :deprecate

        add_changeset :patch, :type => :remove
        add_changeset :major, :type => :remove

        add_changeset :patch, :type => :security
      end

      in_project do
        changesets = collection.changesets_by_types_sorted_by_bump
        expect(changesets.keys)
          .to eql(["add", "change", "deprecate", "remove", "fix", "security"])
        expect(map_changesets(changesets["add"])).to eq([
          ["add", "major"],
          ["add", "minor"],
          ["add", "patch"]
        ])
        expect(map_changesets(changesets["change"])).to eq([
          ["change", "major"],
          ["change", "minor"],
          ["change", "patch"]
        ])
        expect(map_changesets(changesets["deprecate"])).to eq([
          ["deprecate", "patch"]
        ])
        expect(map_changesets(changesets["remove"])).to eq([
          ["remove", "major"],
          ["remove", "patch"]
        ])
        expect(map_changesets(changesets["fix"])).to eq([
          ["fix", "patch"]
        ])
        expect(map_changesets(changesets["security"])).to eq([
          ["security", "patch"]
        ])
      end
    end

    it "only returns present type changesets in a hash per type sorted by version bump" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
        create_changelog
        add_changeset :patch, :type => :fix

        add_changeset :minor, :type => :change
        add_changeset :major, :type => :change

        add_changeset :patch, :type => :security
      end

      in_project do
        changesets = collection.changesets_by_types_sorted_by_bump
        expect(changesets.keys)
          .to eql(["change", "fix", "security"])
        expect(map_changesets(changesets["change"])).to eq([
          ["change", "major"],
          ["change", "minor"]
        ])
        expect(map_changesets(changesets["fix"])).to eq([
          ["fix", "patch"]
        ])
        expect(map_changesets(changesets["security"])).to eq([
          ["security", "patch"]
        ])
      end
    end

    def map_changesets(changesets)
      changesets.map { |changeset| [changeset.type, changeset.bump] }
    end
  end

  describe "#write_changesets_to_changelog" do
    let(:test_project) { :elixir_single }
    let(:config) { config_for(test_project) }
    let(:package) { Mono::Languages::Elixir::Package.new("my-package", ".", config) }
    let(:collection) { described_class.new(config, package) }

    it "writes all changesets to the changelog in order of bump size" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
        create_changelog
        add_changeset :patch, :type => :fix

        add_changeset :patch, :type => :add
        add_changeset :major, :type => :add
        add_changeset :minor, :type => :add

        add_changeset :patch, :type => :change
        add_changeset :minor, :type => :change
        add_changeset :major, :type => :change

        add_changeset :patch, :type => :deprecate

        add_changeset :patch, :type => :remove
        add_changeset :major, :type => :remove

        add_changeset :patch, :type => :security
      end

      in_project do
        collection.write_changesets_to_changelog
        changelog = normalize_changelog(read_changelog_file)
        expect(changelog).to include(<<~CHANGELOG)
          ## 2.0.0

          _Published on #{date_label}._

          ### Added

          - [LINK] major - This is a major changeset bump.
          - [LINK] minor - This is a minor changeset bump.
          - [LINK] patch - This is a patch changeset bump.

          ### Changed

          - [LINK] major - This is a major changeset bump.
          - [LINK] minor - This is a minor changeset bump.
          - [LINK] patch - This is a patch changeset bump.

          ### Deprecated

          - [LINK] patch - This is a patch changeset bump.

          ### Removed

          - [LINK] major - This is a major changeset bump.
          - [LINK] patch - This is a patch changeset bump.

          ### Fixed

          - [LINK] patch - This is a patch changeset bump.

          ### Security

          - [LINK] patch - This is a patch changeset bump.
        CHANGELOG
      end
    end

    it "only writes about types the release includes" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
        create_changelog
        add_changeset :patch, :type => :deprecate
        add_changeset :patch, :type => :remove
        add_changeset :major, :type => :remove
      end

      in_project do
        collection.write_changesets_to_changelog
        changelog = normalize_changelog(read_changelog_file)
        expect(changelog).to include(<<~CHANGELOG)
          ## 2.0.0

          _Published on #{date_label}._

          ### Deprecated

          - [LINK] patch - This is a patch changeset bump.

          ### Removed

          - [LINK] major - This is a major changeset bump.
          - [LINK] patch - This is a patch changeset bump.
        CHANGELOG
      end
    end
  end

  def normalize_changelog(content)
    # Remove links so we don't have to try and match against every instance
    content.gsub(/\[[a-z0-9]{7}\]\(.+\)/, "[LINK]")
  end

  def date_label
    Time.now.utc.strftime("%Y-%m-%d")
  end
end
