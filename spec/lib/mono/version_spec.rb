# frozen_string_literal: true

RSpec.describe Mono::Version do
  def new(*args)
    described_class.new(*args)
  end

  describe "#segments" do
    context "with plain release" do
      it "returns version string" do
        expect(new(1, 0, 0).segments).to eql([1, 0, 0])
        expect(new(1, 2, 3).segments).to eql([1, 2, 3])
      end
    end

    context "with prerelease" do
      it "returns version string" do
        expect(new(1, 0, 0, "alpha", 1).segments).to eql([1, 0, 0, "alpha", 1])
        expect(new(1, 2, 3, "alpha", 10).segments).to eql([1, 2, 3, "alpha", 10])
        expect(new(11, 12, 13, "beta", 20).segments).to eql([11, 12, 13, "beta", 20])
        expect(new(201, 202, 203, "rc", 999).segments).to eql([201, 202, 203, "rc", 999])
      end
    end
  end

  describe "#prerelease?" do
    context "with prerelease" do
      it "returns true" do
        expect(new(1, 2, 3, "alpha", 1).prerelease?).to be_truthy
        expect(new(1, 2, 3, "beta", 2).prerelease?).to be_truthy
        expect(new(1, 2, 3, "rc", 3).prerelease?).to be_truthy
      end
    end

    context "without prerelease" do
      it "returns false" do
        expect(new(1, 2, 3).prerelease?).to be_falsy
      end
    end
  end

  describe "#current_bump" do
    context "with major bump" do
      it "returns major" do
        expect(new(1, 0, 0).current_bump).to eql("major")
        expect(new(1, 0, 0, "alpha", 2).current_bump).to eql("major")
      end
    end

    context "with minor bump" do
      it "returns minor" do
        expect(new(1, 2, 0).current_bump).to eql("minor")
        expect(new(1, 2, 0, "alpha", 3).current_bump).to eql("minor")
      end
    end

    context "with patch bump" do
      it "returns patch" do
        expect(new(1, 2, 3).current_bump).to eql("patch")
        expect(new(1, 2, 3, "alpha", 4).current_bump).to eql("patch")
      end
    end
  end
end

RSpec.describe Mono::Version::Semver do
  def parse(string)
    described_class.parse(string)
  end

  describe ".parse" do
    context "with plain release" do
      it "returns Version object" do
        expect(parse("1.0.0")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
        expect(parse("1.2.3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
      end
    end

    context "with prerelease" do
      it "returns Version object" do
        expect(parse("1.0.0-alpha.1")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3-alpha.1")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3-beta.2")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "beta",
          :prerelease_version => 2
        )
        expect(parse("1.2.3-rc.3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
      end
    end
  end

  describe "#to_s" do
    context "with plain release" do
      it "returns version string" do
        expect(parse("1.0.0").to_s).to eql("1.0.0")
        expect(parse("1.2.3").to_s).to eql("1.2.3")
      end
    end

    context "with prerelease" do
      it "returns Version string" do
        expect(parse("1.0.0-alpha.1").to_s).to eql("1.0.0-alpha.1")
        expect(parse("1.2.3-alpha.10").to_s).to eql("1.2.3-alpha.10")
        expect(parse("11.12.13-beta.20").to_s).to eql("11.12.13-beta.20")
        expect(parse("201.202.203-rc.999").to_s).to eql("201.202.203-rc.999")
      end
    end
  end
end

RSpec.describe Mono::Version::Ruby do
  def parse(string)
    described_class.parse(string)
  end

  describe ".parse" do
    context "with plain release" do
      it "returns Version object" do
        expect(parse("1.0.0")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
        expect(parse("1.2.3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
      end
    end

    context "with prerelease" do
      it "returns Version object" do
        expect(parse("1.0.0.alpha.1")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3.alpha.1")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3.beta.2")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "beta",
          :prerelease_version => 2
        )
        expect(parse("1.2.3.rc.3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
      end
    end
  end

  describe "#to_s" do
    context "with plain release" do
      it "returns version string" do
        expect(parse("1.0.0").to_s).to eql("1.0.0")
        expect(parse("1.2.3").to_s).to eql("1.2.3")
      end
    end

    context "with prerelease" do
      it "returns version string" do
        expect(parse("1.0.0.alpha.1").to_s).to eql("1.0.0.alpha.1")
        expect(parse("1.2.3.alpha.10").to_s).to eql("1.2.3.alpha.10")
        expect(parse("11.12.13.beta.20").to_s).to eql("11.12.13.beta.20")
        expect(parse("201.202.203.rc.999").to_s).to eql("201.202.203.rc.999")
      end
    end
  end
end

RSpec.describe Mono::Version::Python do
  def parse(string)
    described_class.parse(string)
  end

  describe ".parse" do
    context "with plain release" do
      it "returns Version object" do
        expect(parse("1.0.0")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
        expect(parse("1.2.3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
      end
    end

    context "with plain release with extra segments" do
      it "ignores extra segments and returns Version object" do
        expect(parse("1.2.3.4")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => nil,
          :prerelease_version => nil
        )
      end
    end

    context "with prerelease" do
      it "returns Version object" do
        expect(parse("1.0.0a1")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3a1")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3b2")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "beta",
          :prerelease_version => 2
        )
        expect(parse("1.2.3rc3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
      end
    end

    context "with compatibility prerelease types" do
      it "returns Version object" do
        expect(parse("1.2.3alpha1")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse("1.2.3beta2")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "beta",
          :prerelease_version => 2
        )
        expect(parse("1.2.3c3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
        expect(parse("1.2.3pre3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
        expect(parse("1.2.3preview3")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "rc",
          :prerelease_version => 3
        )
      end
    end

    context "with compatibility prerelease separators" do
      it "returns Version object" do
        [
          "1.2.3.a1",
          "1.2.3-a1",
          "1.2.3_a1",
          "1.2.3a.1",
          "1.2.3a-1",
          "1.2.3a_1"
        ].each do |version_string|
          expect(parse(version_string)).to have_attributes(
            :major => 1,
            :minor => 2,
            :patch => 3,
            :prerelease_type => "alpha",
            :prerelease_version => 1
          )
        end
      end
    end
  end

  describe "#to_s" do
    context "with plain release" do
      it "returns version string" do
        expect(parse("1.0.0").to_s).to eql("1.0.0")
        expect(parse("1.2.3").to_s).to eql("1.2.3")
      end
    end

    context "with prerelease" do
      it "returns version string" do
        expect(parse("1.0.0a1").to_s).to eql("1.0.0a1")
        expect(parse("1.2.3a10").to_s).to eql("1.2.3a10")
        expect(parse("11.12.13b20").to_s).to eql("11.12.13b20")
        expect(parse("201.202.203rc999").to_s).to eql("201.202.203rc999")
      end
    end
  end
end
