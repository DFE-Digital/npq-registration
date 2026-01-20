require "rails_helper"

RSpec.describe ExternalLinkHelper, type: :helper do
  before do
    ExternalLink.reset_cache
    allow(YAML).to receive(:load_file).with(ExternalLink::CONFIG_PATH).and_return({
      "good" => { "url" => "https://example.org" },
    })
  end

  after do
    ExternalLink.reset_cache
  end

  describe "#external_link_to without a block" do
    subject do
      helper.external_link_to("Normal Text", :good, new_tab: true)
    end

    let(:expected_html) do
      helper.govuk_link_to("Normal Text", "https://example.org", new_tab: true)
    end

    it "returns a link to the external link" do
      expect(subject).to eq(expected_html)
    end
  end

  describe "#external_link_to with a block" do
    subject do
      helper.external_link_to(:good, new_tab: true) do
        "Block Text"
      end
    end

    let(:expected_html) do
      helper.govuk_link_to("https://example.org", new_tab: true) { "Block Text" }
    end

    it "returns a link to the external link" do
      expect(subject).to eq(expected_html)
    end
  end

  describe "#external_link_to with a non-existent key" do
    subject do
      helper.external_link_to("Text", :nope)
    end

    it "raises an error" do
      expect { subject }.to raise_error(KeyError)
    end
  end
end
