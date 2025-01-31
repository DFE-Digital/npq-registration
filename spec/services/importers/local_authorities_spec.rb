require "rails_helper"

RSpec.describe Importers::LocalAuthorities do
  describe "#call" do
    subject { described_class.new(path_to_csv: Rails.root.join("config/data/local_authorities.csv")) }

    it "import local authorities" do
      expect { subject.call }.to change(LocalAuthority, :count).by(5)

      record = LocalAuthority.first

      expect(record.ukprn).to eql("10005549")
      expect(record.name).to eql("Royal Borough of Kingston upon Thames")
      expect(record.address_1).to eql("Guildhall")
      expect(record.address_2).to eql("2 High Street")
      expect(record.address_3).to be_nil
      expect(record.town).to eql("Kingston Upon Thames")
      expect(record.county).to eql("Surrey")
      expect(record.postcode).to eql("KT1 1EU")
      expect(record.postcode_without_spaces).to eql("KT11EU")
      expect(record.high_pupil_premium).to be_falsey
    end

    it "does not create dupes called multiple times" do
      expect {
        subject.call
        subject.call
      }.to change(LocalAuthority, :count).by(5)
    end

    context "when incorrect headers" do
      subject { described_class.new(path_to_csv: file.path) }

      let(:file) { Tempfile.new("test.csv") }

      before do
        file.write("application_id,trn")
        file.write("\n")
        file.rewind
      end

      it "raises an error" do
        expect {
          subject.call
        }.to raise_error(NameError)
      end
    end
  end
end
