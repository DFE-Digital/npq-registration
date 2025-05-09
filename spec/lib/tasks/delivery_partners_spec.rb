require "rails_helper"

RSpec.describe "Delivery Partners rake tasks" do
  describe "delivery_partners:partners:export" do
    subject :csv_data do
      Rake::Task["delivery_partners:partners:export"].invoke(csv_file)
      CSV.read(csv_file)
    end

    before { partners }
    after { Rake::Task["delivery_partners:partners:export"].reenable }

    let(:csv_file) { Tempfile.new.path }
    let(:partners) { create_list :delivery_partner, 3 }

    it { is_expected.to have_attributes length: 4 }

    context "with heading row" do
      subject { csv_data[0] }

      it { is_expected.to eq ["ECF Id", "Name"] }
    end

    context "with data row" do
      subject { csv_data[1] }

      it { is_expected.to eq [partners[0].ecf_id, partners[0].name] }
    end

    context "without specifying export file" do
      let(:csv_file) { nil }

      it { expect { csv_data }.to raise_exception "Export file not specified" }
    end
  end

  describe "delivery_partners:partnerships:export" do
    subject :csv_data do
      Rake::Task["delivery_partners:partnerships:export"].invoke(csv_file)
      CSV.read(csv_file, headers: true)
    end

    before { partnerships }
    after { Rake::Task["delivery_partners:partnerships:export"].reenable }

    let(:csv_file) { Tempfile.new.path }
    let :partnerships do
      create_list(:delivery_partner, 3, lead_provider: create(:lead_provider))
        .flat_map(&:delivery_partnerships)
    end

    it { is_expected.to have_attributes length: 3 }

    context "with heading row" do
      subject { csv_data[0].to_h.keys }

      let :expected_header do
        ["Lead Provider ECF Id", "Cohort Start Year", "Delivery Partner ECF Id"]
      end

      it { is_expected.to eq expected_header }
    end

    context "with data row" do
      subject { csv_data[0].to_h }

      let(:partnership) { partnerships[0] }

      it { is_expected.to have_attributes length: 3 }
      it { is_expected.to include "Lead Provider ECF Id" => partnership.lead_provider.ecf_id }
      it { is_expected.to include "Cohort Start Year" => partnership.cohort.start_year.to_s }
      it { is_expected.to include "Delivery Partner ECF Id" => partnership.delivery_partner.ecf_id }
    end

    context "without specifying export file" do
      let(:csv_file) { nil }

      it { expect { csv_data }.to raise_exception "Export file not specified" }
    end
  end
end
