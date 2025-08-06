require "rails_helper"

RSpec.describe BulkOperation::SubmitDeclarations do
  let(:admin) { create(:admin) }
  let(:bulk_operation) { create(:submit_declarations_bulk_operation, admin: admin) }

  let(:cohort) { create(:cohort, start_year: 2023) }
  let(:course) { create(:course, identifier: "leadership-development") }
  let(:lead_provider) { create(:lead_provider) }
  let(:delivery_partner) { create(:delivery_partner) }
  let(:schedule) { create(:schedule, cohort:, course_group: course.course_group, allowed_declaration_types: %w[started]) }
  let(:statement) { create(:statement, cohort:, lead_provider:) }
  let(:participant) { create(:user) }

  let!(:application) { create(:application, :accepted, user: participant, cohort:, course:, lead_provider:, schedule:) }

  describe "validations" do
    context "with valid CSV file" do
      let(:valid_csv_file) do
        tempfile <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
          #{participant.ecf_id},started,2023-01-01T00:00:00Z,#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
        CSV
      end

      before do
        bulk_operation.file.attach(valid_csv_file.open)
      end

      it "is valid" do
        expect(bulk_operation).to be_valid
      end
    end

    context "with invalid CSV format" do
      let(:invalid_csv_file) do
        tempfile <<~CSV
          wrong,headers,in,csv,file,here
          value1,value2,value3,value4,value5,value6
        CSV
      end

      before do
        bulk_operation.file.attach(invalid_csv_file.open)
      end

      it "is invalid" do
        expect(bulk_operation).not_to be_valid
        expect(bulk_operation.errors[:file]).to include("Uploaded file is wrong format")
      end
    end

    context "with empty CSV file" do
      let(:empty_csv_file) do
        tempfile <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
        CSV
      end

      before do
        bulk_operation.file.attach(empty_csv_file.open)
      end

      it "is invalid" do
        expect(bulk_operation).not_to be_valid
        expect(bulk_operation.errors[:file]).to include("Uploaded file is empty")
      end
    end
  end

  describe "#run!" do
    subject(:run) { bulk_operation.run! }

    let(:csv_file) { tempfile(csv) }

    before do
      create(:contract, statement:, course:)
      create(:delivery_partnership, cohort:, delivery_partner:, lead_provider:)

      bulk_operation.file.attach(csv_file.open)
      bulk_operation.save!
    end

    context "when the entire CSV is valid" do
      let(:participant2) { create(:user) }
      let!(:application2) { create(:application, :accepted, user: participant2, cohort:, course:, lead_provider:, schedule:) }

      let(:csv) do
        <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
          #{participant.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          #{participant2.ecf_id},started,#{(schedule.applies_from + 1.day).rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
        CSV
      end

      it "creates declarations for all rows" do
        expect { run }.to change(Declaration, :count).by(2)
      end

      it "saves successful results for all rows" do
        run
        result = JSON.parse(bulk_operation.reload.result)
        expect(result["1"]).to eq("Declaration created successfully")
        expect(result["2"]).to eq("Declaration created successfully")
      end

      it "creates declarations with correct attributes" do
        run
        declaration1 = Declaration.find_by(application: application)
        declaration2 = Declaration.find_by(application: application2)

        expect(declaration1.declaration_type).to eq("started")
        expect(declaration1.delivery_partner).to eq(delivery_partner)
        expect(declaration2.declaration_type).to eq("started")
        expect(declaration2.delivery_partner).to eq(delivery_partner)
      end
    end

    context "when some rows are invalid" do
      let(:csv) do
        <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
          #{participant.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          nonexistent-participant-id,started,#{(schedule.applies_from + 1.day).rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
        CSV
      end

      it "creates declarations for valid rows only" do
        expect { run }.to change(Declaration, :count).by(1)
      end

      it "sets finished_at timestamp" do
        run
        expect(bulk_operation.reload.finished_at).to be_present
      end

      it "records both success and failure results" do
        run
        result = JSON.parse(bulk_operation.reload.result)
        expect(result["1"]).to eq("Declaration created successfully")
        expect(result["2"]).to eq("Participant not found")
      end
    end

    context "with details of individual errors" do
      context "when participant does not exist" do
        let(:csv) do
          <<~CSV
            participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
            nonexistent-participant-id,started,2023-01-01T00:00:00Z,#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          CSV
        end

        it "returns error message for missing participant" do
          run
          result = JSON.parse(bulk_operation.reload.result)
          expect(result["1"]).to eq("Participant not found")
        end
      end

      context "when application does not exist" do
        let(:participant_without_app) { create(:user) }

        let(:csv) do
          <<~CSV
            participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
            #{participant_without_app.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          CSV
        end

        it "returns error message for missing application" do
          run
          result = JSON.parse(bulk_operation.reload.result)
          expect(result["1"]).to include("Your update cannot be made as the '#/participant_id' is not recognised")
        end
      end

      context "when lead provider does not exist" do
        let(:csv) do
          <<~CSV
            participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
            #{participant.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},NonExistentProvider,
          CSV
        end

        it "returns error message for missing lead provider" do
          run
          result = JSON.parse(bulk_operation.reload.result)
          expect(result["1"]).to eq("Lead provider not found")
        end
      end

      context "when declaration service validation fails" do
        let(:csv) do
          <<~CSV
            participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
            #{participant.ecf_id},invalid_type,2023-01-01T00:00:00Z,#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          CSV
        end

        it "returns validation error messages" do
          run
          result = JSON.parse(bulk_operation.reload.result)
          expect(result["1"]).to include("The entered '#/declaration_type' is not recognised")
        end
      end
    end
  end
end
