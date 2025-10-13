require "rails_helper"

RSpec.describe PaperTrailExtensions::Version, :versioning, type: :model do
  before do
    freeze_time
    PaperTrail.request.whodunnit = "Admin 1"
    allow(StreamVersionsToBigQueryJob).to receive(:perform_later).and_call_original
  end

  context "when a model has paper trail enabled" do
    let(:user) { create(:user, full_name: "John Doe") }
    let(:user_name) { "Admin 1" }

    context "when a record is created" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "create",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => %w[
            id
            email
            created_at
            ecf_id
            trn
            full_name
            date_of_birth
            significantly_updated_at
          ],
        }
      end

      before { user }

      it "calls StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).to have_received(:perform_later).with(user_name, expected_data)
      end
    end

    context "when a user is updated" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "update",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => %w[
            full_name
          ],
        }
      end

      before do
        user
        user.update!(full_name: "New name")
      end

      it "calls StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).to have_received(:perform_later).with(user_name, expected_data)
      end
    end

    context "when a record is destroyed" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "destroy",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => user.attributes.keys.excluding(%w[updated_at raw_tra_provider_data feature_flag_id]),
        }
      end

      before do
        user
        user.destroy!
      end

      it "calls StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).to have_received(:perform_later).with(user_name, expected_data)
      end
    end
  end

  context "when a child class does not have paper trail enabled" do
    context "when a record is created" do
      before { create(:course) }

      it "does not call StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    context "when a record is updated" do
      before do
        course = create(:course)
        course.update!(name: "New name")
      end

      it "does not call StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    context "when a record is destroyed" do
      before do
        course = create(:course)
        course.destroy!
      end

      it "does not call StreamVersionsToBigQueryJob" do
        expect(StreamVersionsToBigQueryJob).not_to have_received(:perform_later)
      end
    end
  end
end
