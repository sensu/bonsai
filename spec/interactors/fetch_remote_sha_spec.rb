require "spec_helper"

describe FetchRemoteSha do
  let(:asset_filename)   { "some-asset.gz" }
  let(:sha_download_url) { "http://example.com" }
  let(:sha_file_content) { "" }
  subject(:context)      { FetchRemoteSha.call(asset_filename:   asset_filename,
                                               sha_download_url: sha_download_url) }

  before do
    allow_any_instance_of(Faraday::Response).to receive(:success?) { true }
    allow_any_instance_of(Faraday::Response).to receive(:body)     { sha_file_content }
  end

  describe ".call" do
    context "SHA content is empty" do
      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns a nil SHA" do
        expect(context.sha).to be_nil
      end
    end

    context "SHA content is one SHA line" do
      let(:sha)              { "c6c2926c7179993b7099a04780ab" }
      let(:sha_file_content) { "  # Comment line\n\n#{sha} some other cruft\n\nNot a SHA\n"}

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns a nil SHA" do
        expect(context.sha).to eql(sha)
      end
    end

    context "SHA content has multiple SHA lines" do
      let(:sha_lines)        {
        <<~EOSHAS
          b05fca0917280ac4e837    ./sensu-slack-handler_0.1.4_freebsd_amd64.tar.gz

          // This is the one that will match:
          3293fe0bffcf1f8460a0    ./sensu-slack-handler_0.1.4_linux_386.tar.gz
          31d9bcc2bfee0e98bf49    ./sensu-slack-handler_0.1.4_linux_amd64.tar.gz
        EOSHAS
      }
      let(:sha_file_content) { "  # Comment line\n\n#{sha_lines}\n\nNot a SHA\n"}

      context "with a known asset filename" do
        let(:asset_filename)   { "sensu-slack-handler_0.1.4_linux_386.tar.gz" }

        it "succeeds" do
          expect(context).to be_a_success
        end

        it "returns the matching SHA" do
          expect(context.sha).to eql("3293fe0bffcf1f8460a0")
        end
      end

      context "with an unknown asset filename" do
        let(:asset_filename)   { "unknown-asset.gz" }

        it "succeeds" do
          expect(context).to be_a_success
        end

        it "returns a nil SHA" do
          expect(context.sha).to be_nil
        end
      end
    end
  end
end
