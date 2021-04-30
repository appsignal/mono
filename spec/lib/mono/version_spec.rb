# frozen_string_literal: true

RSpec.describe Mono::Version do
  def parse(string)
    described_class.parse(string)
  end

  def parse_ruby(string)
    described_class.parse_ruby(string)
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

    context "with prerelease using a dash (-)" do
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

    context "with prerelease using a dot (.)" do
      it "returns Version object" do
        expect(parse_ruby("1.0.0.alpha.1")).to have_attributes(
          :major => 1,
          :minor => 0,
          :patch => 0,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse_ruby("1.2.3.alpha.1")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "alpha",
          :prerelease_version => 1
        )
        expect(parse_ruby("1.2.3.beta.2")).to have_attributes(
          :major => 1,
          :minor => 2,
          :patch => 3,
          :prerelease_type => "beta",
          :prerelease_version => 2
        )
        expect(parse_ruby("1.2.3.rc.3")).to have_attributes(
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

    context "with prerelease using a dash (-)" do
      it "returns version string" do
        expect(parse("1.0.0-alpha.1").to_s).to eql("1.0.0-alpha.1")
        expect(parse("1.2.3-alpha.10").to_s).to eql("1.2.3-alpha.10")
        expect(parse("11.12.13-beta.20").to_s).to eql("11.12.13-beta.20")
        expect(parse("201.202.203-rc.999").to_s).to eql("201.202.203-rc.999")
      end
    end

    context "with prerelease using a dot (.)" do
      it "returns Version string" do
        expect(parse_ruby("1.0.0.alpha.1").to_s).to eql("1.0.0.alpha.1")
        expect(parse_ruby("1.2.3.alpha.10").to_s).to eql("1.2.3.alpha.10")
        expect(parse_ruby("11.12.13.beta.20").to_s).to eql("11.12.13.beta.20")
        expect(parse_ruby("201.202.203.rc.999").to_s).to eql("201.202.203.rc.999")
      end
    end
  end

  describe "#prerelease_bump" do
    context "with major prerelease" do
      it "returns major" do
        expect(parse("1.0.0-alpha.2").prerelease_bump).to eql(:major)
        expect(parse_ruby("3.0.0.alpha.4").prerelease_bump).to eql(:major)
      end
    end

    context "with minor prerelease" do
      it "returns minor" do
        expect(parse("1.2.0-alpha.3").prerelease_bump).to eql(:minor)
        expect(parse_ruby("3.4.0.alpha.5").prerelease_bump).to eql(:minor)
      end
    end

    context "with patch prerelease" do
      it "returns patch" do
        expect(parse("1.2.3-alpha.4").prerelease_bump).to eql(:patch)
        expect(parse_ruby("5.6.7.alpha.8").prerelease_bump).to eql(:patch)
      end
    end

    context "without prerelease" do
      it "returns nil" do
        expect(parse("1.2.3").prerelease_bump).to be_nil
      end
    end
  end

  describe "#prerelease?" do
    context "with prerelease" do
      context "using a dash (-)" do
        it "returns true" do
          expect(parse("1.2.3-alpha.1").prerelease?).to be_truthy
          expect(parse("1.2.3-beta.2").prerelease?).to be_truthy
          expect(parse("1.2.3-rc.3").prerelease?).to be_truthy
        end
      end

      context "using a dot (.)" do
        it "returns true" do
          expect(parse_ruby("1.2.3.alpha.1").prerelease?).to be_truthy
          expect(parse_ruby("1.2.3.beta.2").prerelease?).to be_truthy
          expect(parse_ruby("1.2.3.rc.3").prerelease?).to be_truthy
        end
      end
    end

    context "without prerelease" do
      it "returns false" do
        expect(parse("1.2.3").prerelease?).to be_falsy
      end
    end
  end

  describe "#prerelease_bump" do
    context "with major prerelease" do
      it "returns major" do
        expect(parse("1.0.0-alpha.2").prerelease_bump).to eql(:major)
        expect(parse_ruby("3.0.0.alpha.4").prerelease_bump).to eql(:major)
      end
    end

    context "with minor prerelease" do
      it "returns minor" do
        expect(parse("1.2.0-alpha.3").prerelease_bump).to eql(:minor)
        expect(parse_ruby("3.4.0.alpha.5").prerelease_bump).to eql(:minor)
      end
    end

    context "with patch prerelease" do
      it "returns patch" do
        expect(parse("1.2.3-alpha.4").prerelease_bump).to eql(:patch)
        expect(parse_ruby("5.6.7.alpha.8").prerelease_bump).to eql(:patch)
      end
    end

    context "without prerelease" do
      it "returns nil" do
        expect(parse("1.2.3").prerelease_bump).to be_nil
      end
    end
  end
end
