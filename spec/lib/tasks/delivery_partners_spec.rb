require "rails_helper"

RSpec.describe "Delivery Partners rake tasks" do
  before { allow(Rails.logger).to receive(:info).and_call_original }

  describe "delivery_partners:partners:import" do
    subject :run_task do
      Rake::Task["delivery_partners:partners:import"].invoke(csv_path, dry_run)
    end

    after { Rake::Task["delivery_partners:partners:import"].reenable }

    let(:partners) { attributes_for_list :delivery_partner, 3 }
    let(:dry_run) { "false" }
    let(:csv_path) { csv_file.path }

    let :csv_file do
      Tempfile.new.tap do |tmp|
        CSV.open(tmp.path, "w") do |csv|
          csv << ["ECF Id", "Name"]

          partners.each do |partner|
            csv << [partner[:ecf_id], partner[:name]]
          end
        end
      end
    end

    context "with valid delivery partner details" do
      subject { run_task && DeliveryPartner.find_by!(ecf_id: partners[0][:ecf_id]) }

      it { expect { run_task }.to change(DeliveryPartner, :count).from(0).to(3) }
      it { is_expected.to have_attributes name: partners[0][:name] }
    end

    context "without specifying import file" do
      let(:csv_path) { nil }

      it { expect { run_task }.to raise_exception "Import file not specified" }
    end

    context "with empty file" do
      let(:csv_file) { Tempfile.new }

      it { expect { run_task }.to raise_exception "Import file is empty" }
    end

    context "with Delivery Partners already present" do
      before { create :delivery_partner }

      it "rejects the import" do
        expect { run_task }
          .to raise_exception("Delivery Partners already exist")
              .and(not_change(DeliveryPartner, :count))
      end
    end

    context "with invalid file" do
      let :partners do
        attributes_for_list(:delivery_partner, 3).tap do |partners|
          partners[2][:ecf_id] = partners[0][:ecf_id]
        end
      end

      it "rejects the import" do
        expect { run_task }
          .to raise_exception(ActiveRecord::RecordInvalid)
              .and(not_change(DeliveryPartner, :count))
      end
    end

    context "with dry_run" do
      let(:dry_run) { nil }

      it "runs the import" do
        run_task

        expect(Rails.logger)
          .to have_received(:info)
                .with("DRY RUN: Imported 3 Delivery Partners, now rolling back")
      end

      it "rolls back" do
        expect { run_task }.not_to change(DeliveryPartner, :count)
      end
    end
  end

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

  describe "delivery_partners:partnerships:import" do
    subject :run_task do
      Rake::Task["delivery_partners:partnerships:import"].invoke(csv_path, dry_run)
    end

    after { Rake::Task["delivery_partners:partnerships:import"].reenable }

    let(:lead_provider) { create :lead_provider }
    let(:cohort) { create(:cohort, :current) }
    let(:delivery_partners) { create_list(:delivery_partner, 3) }
    let(:dry_run) { "false" }
    let(:csv_path) { csv_file.path }

    let :partnerships do
      delivery_partners.map do |partner|
        [lead_provider.ecf_id, cohort.start_year, partner.ecf_id]
      end
    end

    let :csv_file do
      Tempfile.new.tap do |tmp|
        CSV.open(tmp.path, "w") do |csv|
          csv << [
            "Lead Provider ECF Id",
            "Cohort Start Year",
            "Delivery Partner ECF Id",
          ]

          partnerships.each { |partnership| csv << partnership }
        end
      end
    end

    context "with valid delivery partnership details" do
      subject { run_task && imported_partnership }

      let :imported_partnership do
        DeliveryPartnership.find_by(delivery_partner: delivery_partners[0],
                                    cohort:,
                                    lead_provider:)
      end

      it { expect { run_task }.to change(DeliveryPartnership, :count).from(0).to(3) }
      it { is_expected.not_to be_nil }
    end

    context "without specifying import file" do
      let(:csv_path) { nil }

      it { expect { run_task }.to raise_exception "Import file not specified" }
    end

    context "with empty file" do
      let(:csv_file) { Tempfile.new }

      it { expect { run_task }.to raise_exception "Import file is empty" }
    end

    context "with Delivery Partnerships already present" do
      before { create :delivery_partner, lead_provider: create(:lead_provider) }

      it "rejects the import" do
        expect { run_task }
          .to raise_exception("Delivery Partnerships already exist")
              .and(not_change(DeliveryPartnership, :count))
      end
    end

    context "with invalid file" do
      let :partnerships do
        delivery_partners.map do
          [lead_provider.ecf_id, cohort.start_year, delivery_partners[0].ecf_id]
        end
      end

      it "rejects the import" do
        expect { run_task }
          .to raise_exception(ActiveRecord::RecordInvalid)
              .and(not_change(DeliveryPartnership, :count))
      end
    end

    context "with dry_run" do
      let(:dry_run) { nil }

      it "runs the import" do
        run_task

        expect(Rails.logger)
          .to have_received(:info)
                .with("DRY RUN: Imported 3 Delivery Partnerships, now rolling back")
      end

      it "rolls back" do
        expect { run_task }.not_to change(DeliveryPartnership, :count)
      end
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
