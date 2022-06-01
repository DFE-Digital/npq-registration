require "rails_helper"

RSpec.describe Course do
  describe "COURSE_ECF_ID_TO_IDENTIFIER_MAPPING constant" do
    it "returns a hash with the ecf_id to identifier mapping" do
      expect(described_class::COURSE_ECF_ID_TO_IDENTIFIER_MAPPING).to eq({
        "15c52ed8-06b5-426e-81a2-c2664978a0dc" => "npq-leading-teaching",
        "7d47a0a6-fa74-4587-92cc-cd1e4548a2e5" => "npq-leading-behaviour-culture",
        "29fee78b-30ce-4b93-ba21-80be2fde286f" => "npq-leading-teaching-development",
        "a42736ad-3d0b-401d-aebe-354ef4c193ec" => "npq-senior-leadership",
        "0f7d6578-a12c-4498-92a0-2ee0f18e0768" => "npq-headship",
        "aef853f2-9b48-4b6a-9d2a-91b295f5ca9a" => "npq-executive-leadership",
        "7fbefdd4-dd2d-4a4f-8995-d59e525124b7" => "npq-additional-support-offer",
        "0222d1a8-a8e1-42e3-a040-2c585f6c194a" => "npq-early-headship-coaching-offer",
        "66dff4af-a518-498f-9042-36a41f9e8aa7" => "npq-early-years-leadership",
        "829fcd45-e39d-49a9-b309-26d26debfa90" => "npq-leading-literacy",
      })
    end
  end

  describe "#eyl?" do
    context "when the course name is NPQEYL" do
      let(:course) { described_class.new(name: "NPQ for Early Years Leadership (NPQEYL)") }

      it "returns true" do
        expect(course.eyl?).to be true
      end
    end

    context "when the course name is not NPQEYL" do
      let(:course) { described_class.new(name: "something") }

      it "returns false" do
        expect(course.eyl?).to be false
      end
    end
  end

  describe "#identifier" do
    let(:course) { described_class.find_by(name: "NPQ for Senior Leadership (NPQSL)") }

    it "returns the ecf identifier of the course" do
      expect(course.identifier).to eq("npq-senior-leadership")
    end
  end
end
