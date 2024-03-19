require "rails_helper"
require "tempfile"

RSpec.describe GuidancePage, type: :model do
  subject(:guidance_page) { described_class.new("test", content:) }

  describe "#sub_headings" do
    context "when there are no subheadings" do
      let(:content) { "# Heading" }

      it "returns an empty array" do
        expect(guidance_page.sub_headings).to eq([])
      end
    end
  end

  context "when there are subheadings" do
    let(:content) do
      <<~MARKDOWN
        # Heading
        ## Subheading1
        ## Subheading2
        ### Subheading3
      MARKDOWN
    end

    it "returns all subheadings in the markdown file" do
      expect(guidance_page.sub_headings).to eq(%w[Subheading1 Subheading2])
    end
  end
end
