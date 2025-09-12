require "rails_helper"

RSpec.describe ExternalLink, type: :model do
  let(:logger) { instance_double(Logger, info: nil, fatal: nil) }
  let(:good_url) { "https://example.org/200" }
  let(:bad_url) { "https://example.org/404" }
  let(:good_instance) { described_class.new(good_url) }

  before do
    described_class.logger = logger
    allow(YAML).to receive(:load_file).with(ExternalLink.config_path).and_return({
      "good" => good_url,
      "bad" => bad_url,
    })
    stub_request(:get, good_url).to_return(status: 302, headers: { "Location" => "https://example.org/redirected/200" })
    stub_request(:get, "https://example.org/redirected/200").to_return(status: 200)
    stub_request(:get, bad_url).to_return(status: 302, headers: { "location" => "https://example.org/redirected/404" })
    stub_request(:get, "https://example.org/redirected/404").to_return(status: 404)
  end

  after do
    described_class.logger = nil
  end

  describe ".all" do
    subject { described_class.all }

    it "returns all external links" do
      expect(subject.count).to eq(2)
      expect(subject[0]).to be_a(described_class).and have_attributes(url: good_url)
      expect(subject[1]).to be_a(described_class).and have_attributes(url: bad_url)
    end
  end

  describe ".fetch" do
    it "returns the right instance for a given key" do
      expect(described_class.fetch("good")).to be_a(described_class).and have_attributes(url: good_url)
      expect(described_class.fetch("bad")).to be_a(described_class).and have_attributes(url: bad_url)
    end

    it "raises an exception if the key is not found" do
      expect { described_class.fetch("not-found") }.to raise_error(KeyError)
    end
  end

  describe ".verify_all" do
    it "raises an exception if any external links are invalid" do
      expect { described_class.verify_all }.to raise_error(ExternalLink::VerificationError)
    end
  end

  describe "#verify" do
    subject(:verify) { instance.verify }

    context "when the URL responds with a success status" do
      let(:instance) { good_instance }

      it "logs success" do
        subject
        expect(logger).to have_received(:info).with("External link #{good_url} verified successfully")
      end

      it "does not raise an exception" do
        expect { subject }.not_to raise_error
      end
    end

    context "when the URL responds with a non-success status" do
      let(:instance) { described_class.new(bad_url) }

      it "logs failure" do
        begin
          subject
        rescue ExternalLink::VerificationError # rubocop:disable Lint/SuppressedException
        end
        expect(logger).to have_received(:fatal).with("External link #{bad_url} failed verification: URL returned status 404")
      end

      it "raises an exception" do
        expect { subject }.to raise_error(ExternalLink::VerificationError, "URL returned status 404")
      end
    end

    context "when the URL is redirected too many times" do
      let(:loop_url) { "https://example.org/loop" }
      let(:instance) { described_class.new(loop_url) }

      before { stub_request(:get, loop_url).to_return(status: 302, headers: { "Location" => loop_url }) }

      it "logs failure" do
        begin
          subject
        rescue ExternalLink::VerificationError # rubocop:disable Lint/SuppressedException
        end
        expect(logger).to have_received(:fatal).with("External link #{loop_url} failed verification: Too many redirects")
      end

      it "raises an exception" do
        expect { subject }.to raise_error(ExternalLink::VerificationError, "Too many redirects")
      end
    end

    context "when the URL is redirected with a cookie" do
      let(:instance) { described_class.new("https://example.org/cookie") }

      before do
        redirect_url = "https://example.org/redirected/200"
        cookie_value = "cookie=value"
        stub_request(:get, instance.url).to_return(status: 302, headers: { "Location" => redirect_url, "Set-Cookie" => cookie_value })
        stub_request(:get, redirect_url).with(headers: { "Cookie" => cookie_value }).to_return(status: 200)
      end

      it "sends the cookie to the redirected URL" do
        subject
        expect(logger).to have_received(:info).with("External link #{instance.url} verified successfully")
      end
    end
  end

  describe "#url" do
    it "returns the URL" do
      expect(good_instance.url).to eq(good_url)
    end
  end
end
