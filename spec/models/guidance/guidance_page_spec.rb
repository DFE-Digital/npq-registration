require "rails_helper"

RSpec.describe Guidance::GuidancePage do
  subject(:guidance_page) { described_class.new("test", content:) }

  describe "#sections" do
    context "when there are no subheadings" do
      let(:content) { "# Heading" }

      it "returns an empty array" do
        expect(guidance_page.sections).to eq({})
      end
    end
  end

  describe "#index_page?" do
    let(:content) { "# Heading" }

    it "returns false" do
      expect(guidance_page.index_page?).to be false
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
      expect(guidance_page.sections).to eq(
        "#sub-heading-1" => "SubHeading 1",
        "#sub-heading-2" => "SubHeading 2",
      )
    end
  end
end
