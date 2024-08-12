require "rails_helper"
require "tempfile"

RSpec.describe Importers::ManualValidation do
  let(:school) { create(:school) }
  let(:user) { create(:user) }
  let(:trn) { "7654321" }
  let(:application) { create(:application, user:, school:) }
  let(:file) { Tempfile.new("test.csv") }

  around do |example|
    original_stdout = $stdout
    $stdout = File.open(File::NULL, "w")

    example.run

    $stdout = original_stdout
  end

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
        file.write("#{application.ecf_id},#{trn}")
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

      context "when application trn is less than 7 digits" do
        let(:trn) { "123456" }

        it "adds leading zero" do
          expect {
            subject.call
          }.to change { user.reload.trn }.to("0123456")
        end
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
