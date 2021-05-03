# frozen_string_literal: true

RSpec.describe Mono::VersionPromoter do
  def promote(version, bump, prerelease = nil)
    version_object = Mono::Version.parse(version)
    described_class.promote(version_object, bump, prerelease).to_s
  end

  describe ".promote" do
    context "when promoting to a base release" do
      context "when promoting to a major release" do
        it "bumps to a new major version" do
          expect(promote("1.2.3", "major")).to eql("2.0.0")
          expect(promote("1.2.0", "major")).to eql("2.0.0")
          expect(promote("1.0.0", "major")).to eql("2.0.0")
        end
      end

      context "when promoting to a minor release" do
        it "bumps to a new minor version" do
          expect(promote("1.2.3", "minor")).to eql("1.3.0")
          expect(promote("1.2.0", "minor")).to eql("1.3.0")
          expect(promote("1.0.0", "minor")).to eql("1.1.0")
        end
      end

      context "when promoting to a patch release" do
        it "bumps to a new patch version" do
          expect(promote("1.2.3", "patch")).to eql("1.2.4")
          expect(promote("1.2.4", "patch")).to eql("1.2.5")
        end
      end
    end

    context "when promoting to prerelease" do
      describe "bump to major version" do
        context "with existing major release" do
          context "with existing base release" do
            context "bumps to major version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.0.0", "major", "alpha")).to eql("3.0.0-alpha.1")
                expect(promote("2.0.0", "major", "beta")).to eql("3.0.0-beta.1")
                expect(promote("2.0.0", "major", "rc")).to eql("3.0.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "major", "alpha")).to eql("2.0.0-alpha.2")
                expect(promote("2.0.0-alpha.2", "major", "alpha")).to eql("2.0.0-alpha.3")
              end
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("2.0.0-alpha.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-alpha.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-beta.1", "major", "alpha") } }
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-beta.1", "major", "beta")).to eql("2.0.0-beta.2")
                expect(promote("2.0.0-beta.2", "major", "beta")).to eql("2.0.0-beta.3")
              end
            end

            context "bump to rc" do
              it "only bumps the prelease" do
                expect(promote("2.0.0-beta.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-beta.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "major", "alpha") } }
            end

            context "bump to beta" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "major", "beta") } }
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-rc.1", "major", "rc")).to eql("2.0.0-rc.2")
                expect(promote("2.0.0-rc.2", "major", "rc")).to eql("2.0.0-rc.3")
              end
            end
          end
        end

        context "with existing minor release" do
          context "with existing base release" do
            context "bumps to major version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.1.0", "major", "alpha")).to eql("3.0.0-alpha.1")
                expect(promote("2.1.0", "major", "beta")).to eql("3.0.0-beta.1")
                expect(promote("2.1.0", "major", "rc")).to eql("3.0.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.0-alpha.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.0-alpha.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.0-alpha.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.0-beta.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.0-beta.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.0-beta.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-rc.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.0-rc.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.0-beta.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.0-rc.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.0-rc.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end
        end

        context "with existing patch release" do
          context "with existing base release" do
            context "bumps to major version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.1.3", "major", "alpha")).to eql("3.0.0-alpha.1")
                expect(promote("2.1.3", "major", "beta")).to eql("3.0.0-beta.1")
                expect(promote("2.1.3", "major", "rc")).to eql("3.0.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.3-alpha.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.3-alpha.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.3-alpha.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.3-beta.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.3-beta.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.3-beta.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-rc.1", "major", "alpha")).to eql("2.0.0-alpha.1")
                expect(promote("1.2.3-rc.2", "major", "alpha")).to eql("2.0.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "major", "beta")).to eql("2.0.0-beta.1")
                expect(promote("1.2.3-beta.2", "major", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to major version and resets prerelease" do
                expect(promote("1.2.3-rc.1", "major", "rc")).to eql("2.0.0-rc.1")
                expect(promote("1.2.3-rc.2", "major", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end
        end
      end
      # End of bump to major

      describe "bump to minor version" do
        context "with existing major release" do
          context "with existing base release" do
            context "bumps to minor version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.0.0", "minor", "alpha")).to eql("2.1.0-alpha.1")
                expect(promote("2.0.0", "minor", "beta")).to eql("2.1.0-beta.1")
                expect(promote("2.0.0", "minor", "rc")).to eql("2.1.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "minor", "alpha")).to eql("2.0.0-alpha.2")
                expect(promote("2.0.0-alpha.2", "minor", "alpha")).to eql("2.0.0-alpha.3")
              end
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "minor", "beta")).to eql("2.0.0-beta.1")
                expect(promote("2.0.0-alpha.2", "minor", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "minor", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-alpha.2", "minor", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-beta.1", "minor", "alpha") } }
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-beta.1", "minor", "beta")).to eql("2.0.0-beta.2")
                expect(promote("2.0.0-beta.2", "minor", "beta")).to eql("2.0.0-beta.3")
              end
            end

            context "bump to rc" do
              it "only bumps the prelease" do
                expect(promote("2.0.0-beta.1", "minor", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-beta.2", "minor", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "minor", "alpha") } }
            end

            context "bump to beta" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "minor", "beta") } }
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-rc.1", "minor", "rc")).to eql("2.0.0-rc.2")
                expect(promote("2.0.0-rc.2", "minor", "rc")).to eql("2.0.0-rc.3")
              end
            end
          end
        end

        context "with existing minor release" do
          context "with existing base release" do
            context "bumps to minor version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.1.0", "minor", "alpha")).to eql("2.2.0-alpha.1")
                expect(promote("2.1.0", "minor", "beta")).to eql("2.2.0-beta.1")
                expect(promote("2.1.0", "minor", "rc")).to eql("2.2.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "minor", "alpha")).to eql("1.2.0-alpha.2")
                expect(promote("1.2.0-alpha.2", "minor", "alpha")).to eql("1.2.0-alpha.3")
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "minor", "beta")).to eql("1.2.0-beta.1")
                expect(promote("1.2.0-alpha.2", "minor", "beta")).to eql("1.2.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "minor", "rc")).to eql("1.2.0-rc.1")
                expect(promote("1.2.0-alpha.2", "minor", "rc")).to eql("1.2.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it do
                expect_downgrade_error { promote("1.2.0-beta.1", "minor", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "minor", "beta")).to eql("1.2.0-beta.2")
                expect(promote("1.2.0-beta.2", "minor", "beta")).to eql("1.2.0-beta.3")
              end
            end

            context "bump to rc" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "minor", "rc")).to eql("1.2.0-rc.1")
                expect(promote("1.2.0-beta.2", "minor", "rc")).to eql("1.2.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to minor version and resets prerelease" do
                expect_downgrade_error { promote("1.2.0-rc.1", "minor", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect_downgrade_error { promote("1.2.0-rc.1", "minor", "beta") }
              end
            end

            context "bump to rc" do
              it "only bumps prerelease" do
                expect(promote("1.2.0-rc.1", "minor", "rc")).to eql("1.2.0-rc.2")
                expect(promote("1.2.0-rc.2", "minor", "rc")).to eql("1.2.0-rc.3")
              end
            end
          end
        end

        context "with existing patch release" do
          context "with existing base release" do
            context "bumps to minor version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.1.3", "minor", "alpha")).to eql("2.2.0-alpha.1")
                expect(promote("2.1.3", "minor", "beta")).to eql("2.2.0-beta.1")
                expect(promote("2.1.3", "minor", "rc")).to eql("2.2.0-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "minor", "alpha")).to eql("1.3.0-alpha.1")
                expect(promote("1.2.3-alpha.2", "minor", "alpha")).to eql("1.3.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "minor", "beta")).to eql("1.3.0-beta.1")
                expect(promote("1.2.3-alpha.2", "minor", "beta")).to eql("1.3.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "minor", "rc")).to eql("1.3.0-rc.1")
                expect(promote("1.2.3-alpha.2", "minor", "rc")).to eql("1.3.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "minor", "alpha")).to eql("1.3.0-alpha.1")
                expect(promote("1.2.3-beta.2", "minor", "alpha")).to eql("1.3.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "minor", "beta")).to eql("1.3.0-beta.1")
                expect(promote("1.2.3-beta.2", "minor", "beta")).to eql("1.3.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "minor", "rc")).to eql("1.3.0-rc.1")
                expect(promote("1.2.3-beta.2", "minor", "rc")).to eql("1.3.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-rc.1", "minor", "alpha")).to eql("1.3.0-alpha.1")
                expect(promote("1.2.3-rc.2", "minor", "alpha")).to eql("1.3.0-alpha.1")
              end
            end

            context "bump to beta" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "minor", "beta")).to eql("1.3.0-beta.1")
                expect(promote("1.2.3-beta.2", "minor", "beta")).to eql("1.3.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to minor version and resets prerelease" do
                expect(promote("1.2.3-rc.1", "minor", "rc")).to eql("1.3.0-rc.1")
                expect(promote("1.2.3-rc.2", "minor", "rc")).to eql("1.3.0-rc.1")
              end
            end
          end
        end
      end
      # End of bump to minor

      describe "bump to patch version" do
        context "with existing major release" do
          context "with existing base release" do
            context "bumps to patch version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("2.0.0", "patch", "alpha")).to eql("2.0.1-alpha.1")
                expect(promote("2.0.0", "patch", "beta")).to eql("2.0.1-beta.1")
                expect(promote("2.0.0", "patch", "rc")).to eql("2.0.1-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "patch", "alpha")).to eql("2.0.0-alpha.2")
                expect(promote("2.0.0-alpha.2", "patch", "alpha")).to eql("2.0.0-alpha.3")
              end
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "patch", "beta")).to eql("2.0.0-beta.1")
                expect(promote("2.0.0-alpha.2", "patch", "beta")).to eql("2.0.0-beta.1")
              end
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-alpha.1", "patch", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-alpha.2", "patch", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-beta.1", "patch", "alpha") } }
            end

            context "bump to beta" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-beta.1", "patch", "beta")).to eql("2.0.0-beta.2")
                expect(promote("2.0.0-beta.2", "patch", "beta")).to eql("2.0.0-beta.3")
              end
            end

            context "bump to rc" do
              it "only bumps the prelease" do
                expect(promote("2.0.0-beta.1", "patch", "rc")).to eql("2.0.0-rc.1")
                expect(promote("2.0.0-beta.2", "patch", "rc")).to eql("2.0.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "patch", "alpha") } }
            end

            context "bump to beta" do
              it { expect_downgrade_error { promote("2.0.0-rc.1", "patch", "beta") } }
            end

            context "bump to rc" do
              it "only bumps the prerelease" do
                expect(promote("2.0.0-rc.1", "patch", "rc")).to eql("2.0.0-rc.2")
                expect(promote("2.0.0-rc.2", "patch", "rc")).to eql("2.0.0-rc.3")
              end
            end
          end
        end

        context "with existing minor release" do
          context "with existing base release" do
            context "bumps to patch version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("1.2.0", "patch", "alpha")).to eql("1.2.1-alpha.1")
                expect(promote("1.2.0", "patch", "beta")).to eql("1.2.1-beta.1")
                expect(promote("1.2.0", "patch", "rc")).to eql("1.2.1-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "patch", "alpha")).to eql("1.2.0-alpha.2")
                expect(promote("1.2.0-alpha.2", "patch", "alpha")).to eql("1.2.0-alpha.3")
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "patch", "beta")).to eql("1.2.0-beta.1")
                expect(promote("1.2.0-alpha.2", "patch", "beta")).to eql("1.2.0-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.0-alpha.1", "patch", "rc")).to eql("1.2.0-rc.1")
                expect(promote("1.2.0-alpha.2", "patch", "rc")).to eql("1.2.0-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it do
                expect_downgrade_error { promote("1.2.0-beta.1", "patch", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "patch", "beta")).to eql("1.2.0-beta.2")
                expect(promote("1.2.0-beta.2", "patch", "beta")).to eql("1.2.0-beta.3")
              end
            end

            context "bump to rc" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.0-beta.1", "patch", "rc")).to eql("1.2.0-rc.1")
                expect(promote("1.2.0-beta.2", "patch", "rc")).to eql("1.2.0-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to patch version and resets prerelease" do
                expect_downgrade_error { promote("1.2.0-rc.1", "patch", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect_downgrade_error { promote("1.2.0-rc.1", "patch", "beta") }
              end
            end

            context "bump to rc" do
              it "only bumps prerelease" do
                expect(promote("1.2.0-rc.1", "patch", "rc")).to eql("1.2.0-rc.2")
                expect(promote("1.2.0-rc.2", "patch", "rc")).to eql("1.2.0-rc.3")
              end
            end
          end
        end

        context "with existing patch release" do
          context "with existing base release" do
            context "bumps to patch version with prerelease" do
              it "bumps version and sets prerelease" do
                expect(promote("1.2.3", "patch", "alpha")).to eql("1.2.4-alpha.1")
                expect(promote("1.2.3", "patch", "beta")).to eql("1.2.4-beta.1")
                expect(promote("1.2.3", "patch", "rc")).to eql("1.2.4-rc.1")
              end
            end
          end

          context "with existing alpha prerelease" do
            context "bump to alpha" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "patch", "alpha")).to eql("1.2.3-alpha.2")
                expect(promote("1.2.3-alpha.2", "patch", "alpha")).to eql("1.2.3-alpha.3")
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "patch", "beta")).to eql("1.2.3-beta.1")
                expect(promote("1.2.3-alpha.2", "patch", "beta")).to eql("1.2.3-beta.1")
              end
            end

            context "bump to rc" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-alpha.1", "patch", "rc")).to eql("1.2.3-rc.1")
                expect(promote("1.2.3-alpha.2", "patch", "rc")).to eql("1.2.3-rc.1")
              end
            end
          end

          context "with existing beta prerelease" do
            context "bump to alpha" do
              it "bumps to patch version and resets prerelease" do
                expect_downgrade_error { promote("1.2.3-beta.1", "patch", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "patch", "beta")).to eql("1.2.3-beta.2")
                expect(promote("1.2.3-beta.2", "patch", "beta")).to eql("1.2.3-beta.3")
              end
            end

            context "bump to rc" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-beta.1", "patch", "rc")).to eql("1.2.3-rc.1")
                expect(promote("1.2.3-beta.2", "patch", "rc")).to eql("1.2.3-rc.1")
              end
            end
          end

          context "with existing rc prerelease" do
            context "bump to alpha" do
              it "bumps to patch version and resets prerelease" do
                expect_downgrade_error { promote("1.2.3-rc.1", "patch", "alpha") }
              end
            end

            context "bump to beta" do
              it "bumps to patch version and resets prerelease" do
                expect_downgrade_error { promote("1.2.3-rc.1", "patch", "beta") }
              end
            end

            context "bump to rc" do
              it "bumps to patch version and resets prerelease" do
                expect(promote("1.2.3-rc.1", "patch", "rc")).to eql("1.2.3-rc.2")
                expect(promote("1.2.3-rc.2", "patch", "rc")).to eql("1.2.3-rc.3")
              end
            end
          end
        end
      end
    end
  end

  def expect_downgrade_error(&block)
    expect(&block).to raise_error(Mono::VersionPromoter::UnsupportedDowngradeError)
  end
end
