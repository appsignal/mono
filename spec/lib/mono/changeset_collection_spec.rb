# frozen_string_literal: true

RSpec.describe Mono::ChangesetCollection do
  describe "#changesets" do
    let(:test_project) { :nodejs_npm_mono }
    let(:config) { config_for(test_project) }
    let(:package) do
      Mono::Languages::Nodejs::Package.new("package_one", "packages/package_one", config)
    end
    let(:collection) { described_class.new(config, package) }
    let(:changesets) { collection.changesets }
    before do
      prepare_project test_project
    end

    context "without changesets" do
      it "returns an empty array" do
        in_project do
          in_package :package_one do
            expect(current_package_changeset_files).to eql([])
          end

          expect(changesets).to eql([])
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
        end
      end
    end
  end

  pending "Test different version bumps"
  pending "Test different version bumps as written to changelog file"
end
