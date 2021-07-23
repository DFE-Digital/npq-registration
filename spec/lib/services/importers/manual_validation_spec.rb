require "rails_helper"
require "tempfile"

RSpec.describe Services::Importers::ManualValidation do
  let(:school) { create(:school) }
  let(:user) { create(:user) }
  let(:application) { create(:application, :with_ecf_id, user: user, school: school) }

  let(:file) { Tempfile.new("test.csv") }

  describe "#call" do
    subject do
      described_class.new(path_to_csv: file.path)
    end

    context "with well formed csv" do
      before do
        file.write("application_ecf_id,validated_trn")
        file.write("\n")
        file.write("123,7654321")
        file.write("\n")
        file.write("#{application.ecf_id},7654321")
        file.rewind
      end

      it "updates trn" do
        expect {
          subject.call
        }.to change { user.reload.trn }.to("7654321")
      end

      it "updates trn_verified to true" do
        expect {
          subject.call
        }.to change { user.reload.trn_verified }.to(true)
      end
    end

    context "with malformed csv" do
      before do
        file.write("application_id,trn")
        file.write("\n")
        file.rewind
      end

      it "raises error" do
        expect {
          subject.call
        }.to raise_error(NameError)
      end
    end
  end
end
