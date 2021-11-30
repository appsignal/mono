# frozen_string_literal: true

RSpec.describe Mono::Changeset do
  describe ".supported_type?" do
    def supported_type?(type)
      described_class.supported_type?(type)
    end

    it "only returns true for supported types" do
      expect(supported_type?("add")).to be_truthy
      expect(supported_type?("change")).to be_truthy
      expect(supported_type?("deprecate")).to be_truthy
      expect(supported_type?("remove")).to be_truthy
      expect(supported_type?("fix")).to be_truthy
      expect(supported_type?("security")).to be_truthy
      expect(supported_type?("unknown")).to be_falsy
      expect(supported_type?("")).to be_falsy
    end
  end

  describe ".supported_bump?" do
    def supported_bump?(bump)
      described_class.supported_bump?(bump)
    end

    it "only returns true for supported bumps" do
      expect(supported_bump?("major")).to be_truthy
      expect(supported_bump?("minor")).to be_truthy
      expect(supported_bump?("patch")).to be_truthy
      expect(supported_bump?("unknown")).to be_falsy
      expect(supported_bump?("")).to be_falsy
    end
  end

  describe ".parse" do
    context "with valid changeset file" do
      it "returns a Changeset object" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Multi-line changeset message\n" \
            "- List item 1\n" \
            "- List item 2\n" \
            "- List item 3\n" \
            "- List item 4"
          path = add_changeset :patch, :message => message
          changeset = described_class.parse(path)
          expect(changeset.path).to eql(path)
          expect(changeset.bump).to eql("patch")
          expect(changeset.message).to eql(message)
        end
      end
    end

    context "without metadata" do
      it "raises a MetadataError" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Multi-line changeset message\n" \
            "- List item 1\n" \
            "- List item 2\n" \
            "- List item 3\n" \
            "- List item 4"
          path = add_changeset :none, :message => message
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::MetadataError)
        end
      end
    end

    context "without change type" do
      it "raises an InvalidChangeset" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Changeset message"
          path = add_changeset :patch, :type => "", :message => message
          message = <<~MESSAGE
            Invalid changeset detected: `.changesets/1_patch.md`
            Violations:
            - Unknown `type` metadata: ``
          MESSAGE
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::InvalidChangeset, message)
        end
      end
    end

    context "with unknown change type" do
      it "raises an InvalidChangeset" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Changeset message"
          path = add_changeset :patch, :type => "unknown", :message => message
          message = <<~MESSAGE
            Invalid changeset detected: `.changesets/1_patch.md`
            Violations:
            - Unknown `type` metadata: `unknown`
          MESSAGE
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::InvalidChangeset, message)
        end
      end
    end

    context "without version bump" do
      it "raises an InvalidChangeset" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Changeset message"
          path = add_changeset "", :type => "add", :message => message
          message = <<~MESSAGE
            Invalid changeset detected: `.changesets/1_.md`
            Violations:
            - Unknown `bump` metadata: ``
          MESSAGE
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::InvalidChangeset, message)
        end
      end
    end

    context "with unknown version bump" do
      it "raises an InvalidChangeset" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Changeset message"
          path = add_changeset :unknown, :type => "add", :message => message
          message = <<~MESSAGE
            Invalid changeset detected: `.changesets/1_unknown.md`
            Violations:
            - Unknown `bump` metadata: `unknown`
          MESSAGE
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::InvalidChangeset, message)
        end
      end
    end

    context "without message" do
      it "raises an EmptyMessageError" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :message => ""
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::EmptyMessageError)
        end
      end
    end
  end

  describe "#bump" do
    let(:changeset) do
      described_class.new(
        ".changesets/1_patch.md",
        { "bump" => bump },
        "Message"
      )
    end

    describe "with major" do
      let(:bump) { "major" }

      it "return major" do
        expect(changeset.bump).to eql("major")
        expect(changeset.bump_index).to eql(0)
      end
    end

    describe "with minor" do
      let(:bump) { "minor" }

      it "returns minor" do
        expect(changeset.bump).to eql("minor")
        expect(changeset.bump_index).to eql(1)
      end
    end

    describe "with patch" do
      let(:bump) { "patch" }

      it "returns patch" do
        expect(changeset.bump).to eql("patch")
        expect(changeset.bump_index).to eql(2)
      end
    end

    describe "with other" do
      let(:bump) { "random" }
      it "raises an UnknownBumpTypeError" do
        expect { changeset.bump }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
        expect { changeset.bump_index }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
      end
    end

    describe "without bump" do
      let(:bump) { "" }
      it "raises an UnknownBumpTypeError" do
        expect { changeset.bump }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
        expect { changeset.bump_index }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
      end
    end
  end

  describe "#commit" do
    it "returns a hash with commit metadat" do
      prepare_project :nodejs_npm_single
      in_project do
        path = add_changeset :patch

        changeset = described_class.parse(path)
        commit = changeset.commit
        expect(commit).to match(
          :date => kind_of(Time),
          :long => kind_of(String),
          :short => kind_of(String)
        )
        expect(commit[:long].length).to be >= 40
        expect(commit[:short].length).to be >= 7
        expect(commit[:short].length).to be < 40
      end
    end
  end
end
