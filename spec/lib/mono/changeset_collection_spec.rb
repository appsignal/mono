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

  pending "Test different version bumps as written to changelog file"
end
