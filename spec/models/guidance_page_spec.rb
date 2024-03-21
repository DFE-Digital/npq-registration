require "rails_helper"
require "tempfile"

RSpec.describe GuidancePage, type: :model do
  subject(:guidance_page) { described_class.new("test", content:) }

  describe ".index_page" do
    it "returns a new instance of GuidanceIndexPage" do
      expect(described_class.index_page).to be_a(GuidancePage::GuidanceIndexPage)
    end
  end

  describe "#sub_headings" do
    context "when there are no subheadings" do
      let(:content) { "# Heading" }

      it "returns an empty array" do
        expect(guidance_page.sub_headings).to eq({})
      end
    end
  end

  context "when there are subheadings" do
    let(:content) do
      <<~MARKDOWN
        # Heading
        ## SubHeading 1
        ## SubHeading 2
        ### SubHeading 3
      MARKDOWN
    end

    it "returns all subheadings in the markdown file" do
      expect(guidance_page.sub_headings).to eq(
        "#sub-heading-1" => "SubHeading 1",
        "#sub-heading-2" => "SubHeading 2"
      )
    end
  end
end
