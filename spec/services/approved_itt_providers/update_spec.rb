require "rails_helper"

RSpec.describe ApprovedIttProviders::Update do
  subject { described_class.call(file_name:) }

  # Clean the DB first
  before { IttProvider.destroy_all }

  context "when given a valid file_name" do
    let(:file_name) { "spec/fixtures/files/approved_itt_providers_sample.csv" }

    context "with no data in the DB" do
      let(:expected_data) do
        [
          { approved: true,
            legal_name: "Alban Academies Trust",
            operating_name: "Alban Federation SCITT",
            removed_at: nil },
          { approved: true,
            legal_name: "Ambition Institute",
            operating_name: "Ambition Institute",
            removed_at: nil },
          { approved: true,
            legal_name: "Anglia Ruskin University Higher Education Corporation",
            operating_name: "Anglia Ruskin University",
            removed_at: nil },
          { approved: true,
            legal_name: "Archway Learning Trust",
            operating_name: "Bluecoat SCITT Alliance Nottingham",
            removed_at: nil },
        ]
      end

      it "updates the whole table" do
        travel_to(Time.zone.parse("2022-12-12 18:00:00"))

        subject

        expect(
          IttProvider.all.order(:legal_name).map do |itt_provider|
            {
              legal_name: itt_provider.legal_name,
              operating_name: itt_provider.operating_name,
              approved: itt_provider.approved,
              removed_at: itt_provider.removed_at,
            }
          end,
        ).to eq(expected_data)
      end
    end

    context "with some data in the DB" do
      let(:unapproved_provider_name) { "not_approved" }
      let(:file_name) { "spec/fixtures/files/approved_itt_providers_exisiting_data_sample.csv" }

      before do
        create(:itt_provider, legal_name: "Bath Spa University", operating_name: "Bath Spa University")
        create(:itt_provider, legal_name: "ARK Schools", operating_name: "ARK Teacher Training")
        create(:itt_provider, legal_name: unapproved_provider_name)
      end

      it "updates some of the records" do
        travel_to(Time.zone.parse("2022-12-12 18:00:00"))

        expect(IttProvider.currently_approved.count).to eq(3)
        subject

        expect(IttProvider.all.count).to eq(7)
        expect(IttProvider.currently_approved.count).to eq(6)
        expect(IttProvider.find_by(legal_name: unapproved_provider_name).approved).to be(false)
      end
    end
  end

  context "when given an invalid file_name" do
    let(:file_name) { "invalid.csv" }

    it "raises a 'file not found' error" do
      expect { subject }.to raise_error(RuntimeError)
    end
  end
end
