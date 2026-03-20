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
      it "returns a ParseResult with a Changeset and no issues" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Multi-line changeset message\n" \
            "- List item 1\n" \
            "- List item 2\n" \
            "- List item 3\n" \
            "- List item 4"
          path = add_changeset :patch, :message => message
          result = described_class.parse(path)
          expect(result.changeset.path).to eql(path)
          expect(result.changeset.bump).to eql("patch")
          expect(result.changeset.message).to eql(message)
          expect(result.issues).to be_empty
        end
      end
    end

    context "without metadata" do
      it "returns a ParseResult with an error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          message = "Multi-line changeset message\n" \
            "- List item 1\n" \
            "- List item 2\n" \
            "- List item 3\n" \
            "- List item 4"
          path = add_changeset :none, :message => message
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include(
            a_string_including("No metadata found")
          )
        end
      end
    end

    context "without change type" do
      it "returns a ParseResult with a missing type error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :type => "", :message => "Changeset message"
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include("Missing `type` metadata")
        end
      end
    end

    context "with unknown change type" do
      it "returns a ParseResult with an unknown type error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :type => "unknown", :message => "Changeset message"
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include("Unknown `type` metadata: `unknown`")
        end
      end
    end

    context "without version bump" do
      it "returns a ParseResult with a missing bump error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset "", :type => "add", :message => "Changeset message"
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include("Missing `bump` metadata")
        end
      end
    end

    context "with unknown version bump" do
      it "returns a ParseResult with an unknown bump error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :unknown, :type => "add", :message => "Changeset message"
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include("Unknown `bump` metadata: `unknown`")
        end
      end
    end

    context "without message" do
      it "returns a ParseResult with an empty message error and no changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :message => ""
          result = described_class.parse(path)
          expect(result.changeset).to be_nil
          expect(result.errors.map(&:message)).to include(
            a_string_including("No changeset message found")
          )
        end
      end
    end

    context "with unknown metadata key" do
      it "returns a ParseResult with a warning and a Changeset" do
        prepare_project :nodejs_npm_single
        in_project do
          FileUtils.mkdir_p(".changesets")
          path = ".changesets/unknown_key.md"
          File.write(path, <<~CHANGESET)
            ---
            bump: patch
            type: add
            foo: bar
            ---

            A change.
          CHANGESET
          result = described_class.parse(path)
          expect(result.changeset).to be_a(described_class)
          expect(result.warnings.map(&:message)).to include("Unknown metadata key: `foo`")
        end
      end
    end
  end

  describe "#type" do
    let(:changeset) do
      described_class.new(
        ".changesets/1_patch.md",
        { "bump" => "patch", "type" => type },
        "Message"
      )
    end

    describe "with add" do
      let(:type) { "add" }

      it "return add" do
        expect(changeset.type).to eql("add")
        expect(changeset.type_index).to eql(0)
        expect(changeset.type_label).to eql("Added")
      end
    end

    describe "with change" do
      let(:type) { "change" }

      it "returns change" do
        expect(changeset.type).to eql("change")
        expect(changeset.type_index).to eql(1)
        expect(changeset.type_label).to eql("Changed")
      end
    end

    describe "with deprecate" do
      let(:type) { "deprecate" }

      it "returns deprecate" do
        expect(changeset.type).to eql("deprecate")
        expect(changeset.type_index).to eql(2)
        expect(changeset.type_label).to eql("Deprecated")
      end
    end

    describe "with remove" do
      let(:type) { "remove" }

      it "returns remove" do
        expect(changeset.type).to eql("remove")
        expect(changeset.type_index).to eql(3)
        expect(changeset.type_label).to eql("Removed")
      end
    end

    describe "with fix" do
      let(:type) { "fix" }

      it "returns fix" do
        expect(changeset.type).to eql("fix")
        expect(changeset.type_index).to eql(4)
        expect(changeset.type_label).to eql("Fixed")
      end
    end

    describe "with security" do
      let(:type) { "security" }

      it "returns security" do
        expect(changeset.type).to eql("security")
        expect(changeset.type_index).to eql(5)
        expect(changeset.type_label).to eql("Security")
      end
    end
  end

  describe "#bump" do
    let(:changeset) do
      described_class.new(
        ".changesets/1_patch.md",
        { "bump" => bump, "type" => "add" },
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
    it "returns a hash with commit metadata" do
      prepare_project :nodejs_npm_single
      in_project do
        path = add_changeset :patch

        changeset = described_class.parse(path).valid!
        commits = changeset.commits
        expect(commits.length).to eq(1)
        commit = commits.first
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

    it "returns a hash with commit metadata from a complex filename" do
      prepare_project :nodejs_npm_single
      in_project do
        path = add_changeset :patch, :filename => "Patch, & \"messagé'"

        changeset = described_class.parse(path).valid!
        commits = changeset.commits
        expect(commits.length).to eq(1)
        commit = commits.first
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

    context "with multiple commits" do
      it "returns a list of multiple commit hashes" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :filename => "the-changeset.md"
          first_commit = commit_sha
          File.open(path, "a+") { |f| f.write "Other changeset text" }
          commit_changeset
          second_commit = commit_sha

          changeset = described_class.parse(path).valid!
          commits = changeset.commits
          expect(commits.length).to eq(2)

          expect(commits[0]).to include(
            :date => kind_of(Time),
            :long => second_commit,
            :short => second_commit[0..6]
          )
          expect(commits[1]).to include(
            :date => kind_of(Time),
            :long => first_commit,
            :short => first_commit[0..6]
          )
        end
      end

      it "returns a hash with the relevant commit metadata" do
        prepare_project :nodejs_npm_single
        in_project do
          path = add_changeset :patch, :filename => "the-changeset.md"
          File.open(path, "a+") { |f| f.write "Other changeset text" }
          commit_long = commit_sha
          commit_changes("Improve changeset text\n\n[skip mono]")

          changeset = described_class.parse(path).valid!
          commits = changeset.commits
          expect(commits.length).to eq(1)
          commit = commits.first
          expect(commit).to include(
            :date => kind_of(Time),
            :long => commit_long,
            :short => commit_long[0..6]
          )
          expect(commit[:long].length).to be >= 40
          expect(commit[:short].length).to be >= 7
          expect(commit[:short].length).to be < 40
        end
      end
    end
  end

  describe "#date" do
    it "returns the commit date" do
      prepare_ruby_project do
        path = add_changeset :patch

        changeset = described_class.parse(path).valid!
        expect(changeset.date).to be_kind_of(Time)
      end
    end

    it "returns a Time of 0 if no valid commit is found" do
      prepare_ruby_project do
        path = add_changeset :patch, :commit => false
        commit_changeset("[skip mono]")

        changeset = described_class.parse(path).valid!
        expect(changeset.date).to eq(Time.at(0))
      end
    end
  end
end
