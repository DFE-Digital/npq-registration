require "rails_helper"

RSpec.describe Services::Admin::DashboardStats do
  let(:start_time) { 7.days.ago }

  let(:get_an_identity_applications_created_before_start_time) { 3 }
  let(:non_get_an_identity_applications_created_before_start_time) { 4 }
  let(:applications_created_before_start_time) do
    get_an_identity_applications_created_before_start_time + non_get_an_identity_applications_created_before_start_time
  end

  let(:get_an_identity_applications_created_since_start_time) { 5 }
  let(:non_get_an_identity_applications_created_since_start_time) { 6 }
  let(:applications_created_since_start_time) do
    get_an_identity_applications_created_since_start_time + non_get_an_identity_applications_created_since_start_time
  end

  let(:applications_created_all_time) do
    applications_created_before_start_time + applications_created_since_start_time
  end
  let(:get_an_identity_applications_created_all_time) do
    get_an_identity_applications_created_before_start_time + get_an_identity_applications_created_since_start_time
  end
  let(:non_get_an_identity_applications_created_all_time) do
    non_get_an_identity_applications_created_before_start_time + non_get_an_identity_applications_created_since_start_time
  end

  before do
    create_list(
      :application,
      get_an_identity_applications_created_before_start_time,
      created_at: start_time - 1.day,
      user: create(:user, provider: :tra_openid_connect),
    )

    create_list(
      :application,
      non_get_an_identity_applications_created_before_start_time,
      created_at: start_time - 1.day,
      user: create(:user, provider: nil),
    )

    create_list(
      :application,
      get_an_identity_applications_created_since_start_time,
      created_at: start_time + 1.day,
      user: create(:user, provider: :tra_openid_connect),
    )

    create_list(
      :application,
      non_get_an_identity_applications_created_since_start_time,
      created_at: start_time + 1.day,
      user: create(:user, provider: nil),
    )
  end

  # Test these methods with a start_time
  # applications_created
  # get_an_identity_applications_created
  # non_get_an_identity_applications_created
  # get_an_identity_applications_created_percentage
  # non_get_an_identity_applications_created_percentage
  context "with a start_time" do
    subject { described_class.new(start_time:) }

    it "returns the correct number of applications created" do
      expect(subject.applications_created).to eq(applications_created_since_start_time)
    end

    it "returns the correct number of get an identity applications created" do
      expect(subject.get_an_identity_applications_created).to eq(get_an_identity_applications_created_since_start_time)
    end

    it "returns the correct number of non get an identity applications created" do
      expect(subject.non_get_an_identity_applications_created).to eq(non_get_an_identity_applications_created_since_start_time)
    end

    it "returns the correct percentage of get an identity applications created" do
      expect(subject.get_an_identity_applications_created_percentage).to eq(
        (get_an_identity_applications_created_since_start_time / applications_created_since_start_time.to_f * 100).to_i,
      )
    end

    it "returns the correct percentage of non get an identity applications created" do
      expect(subject.non_get_an_identity_applications_created_percentage).to eq(
        (non_get_an_identity_applications_created_since_start_time / applications_created_since_start_time.to_f * 100).to_i,
      )
    end
  end

  context "without a start_time" do
    subject { described_class.new }

    it "returns the correct number of applications created" do
      expect(subject.applications_created).to eq(applications_created_all_time)
    end

    it "returns the correct number of get an identity applications created" do
      expect(subject.get_an_identity_applications_created).to eq(get_an_identity_applications_created_all_time)
    end

    it "returns the correct number of non get an identity applications created" do
      expect(subject.non_get_an_identity_applications_created).to eq(non_get_an_identity_applications_created_all_time)
    end

    it "returns the correct percentage of get an identity applications created" do
      expect(subject.get_an_identity_applications_created_percentage).to eq(
        (get_an_identity_applications_created_all_time / applications_created_all_time.to_f * 100).to_i,
      )
    end

    it "returns the correct percentage of non get an identity applications created" do
      expect(subject.non_get_an_identity_applications_created_percentage).to eq(
        (non_get_an_identity_applications_created_all_time / applications_created_all_time.to_f * 100).to_i,
      )
    end
  end
end
