require "rails_helper"

RSpec.describe Services::EarlyYearsFundingChecker do
  let(:query_store) { Services::QueryStore.new(store: store) }

  subject { described_class.new(query_store, course_id) }

  describe "#run" do
    context "when candidate is on Early Years register or CMA and wants to do EYL and is not abroad" do
      let(:course_id) { 9 }
      let(:store) do
        {
          "teacher_catchment" => "england",
          "works_in_school" => "no",
          "works_in_childcare" => "yes",
          "works_in_nursery" => "yes",
          "kind_of_nursery" => "private_nursery",
          "has_ofsted_urn" => "no",
          "institution_identifier" => "PrivateChildcareProvider-EY456789",
        }
      end

      it "returns true" do
        expect(subject.run).to be true
      end
    end

    context "when does not meet all the criteria" do
      let(:course_id) { 4 }
      let(:store) do
        {
          "teacher_catchment" => "england",
          "works_in_school" => "no",
          "works_in_childcare" => "yes",
          "works_in_nursery" => "yes",
          "kind_of_nursery" => "private_nursery",
          "has_ofsted_urn" => "yes",
          "institution_identifier" => "PrivateChildcareProvider-EY456789",
        }
      end

      it "returns false" do
        expect(subject.run).to be false
      end
    end
  end
end
