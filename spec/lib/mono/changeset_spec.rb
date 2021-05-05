# frozen_string_literal: true

RSpec.describe Mono::Changeset do
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
          path = add_changeset :patch, message
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
          path = add_changeset :none, message
          expect do
            described_class.parse(path)
          end.to raise_error(described_class::MetadataError)
        end
      end
    end

    context "without message" do
      it "raises a EmptyMessageError" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, ""
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
    subject { changeset.bump }

    describe "with major" do
      let(:bump) { "major" }
      it { is_expected.to eql("major") }
    end

    describe "with minor" do
      let(:bump) { "minor" }
      it { is_expected.to eql("minor") }
    end

    describe "with patch" do
      let(:bump) { "patch" }
      it { is_expected.to eql("patch") }
    end

    describe "with other" do
      let(:bump) { "random" }
      it "raises an UnknownBumpTypeError" do
        expect { subject }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
      end
    end

    describe "without bump" do
      let(:bump) { "" }
      it "raises an UnknownBumpTypeError" do
        expect { subject }.to raise_error(Mono::Changeset::UnknownBumpTypeError)
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
