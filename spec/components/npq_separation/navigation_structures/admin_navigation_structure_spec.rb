require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

    {
      "Dashboard" => "/npq-separation/admin",
      "Applications" => "/npq-separation/admin/applications",
      "Cohorts" => "/npq-separation/admin/cohorts",
      "Courses" => "/npq-separation/admin/courses",
      "Users" => "/npq-separation/admin/users",
      "Finance" => "/npq-separation/admin/finance/statements",
      "Workplaces" => "/npq-separation/admin/schools",
      "Course providers" => "/npq-separation/admin/lead-providers",
      "Bulk operations" => "/npq-separation/admin/bulk-operations",
      "Delivery partners" => "/npq-separation/admin/delivery-partners",
      "Settings" => "/npq-separation/admin/settings/webhook-messages",
    }.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end

    it "excludes feature flags" do
      expect(subject.map(&:name)).not_to include("Feature flags")
    end

    context "when user is a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

      it "includes reopening email subscriptions" do
        expect(subject[-3]).to have_attributes(name: "Closed registrations")
        expect(subject[-3]).to have_attributes(href: "/npq-separation/admin/registration-closed")
      end

      it "includes feature flags" do
        expect(subject[-2]).to have_attributes(name: "Feature flags")
        expect(subject[-2]).to have_attributes(href: "/npq-separation/admin/features")
      end

      it "includes admins" do
        expect(subject[-1]).to have_attributes(name: "Admins")
        expect(subject[-1]).to have_attributes(href: "/npq-separation/admin/admins")
      end
    end
  end

  describe "#sub_structure" do
    describe "Cohorts" do
      subject { instance.sub_structure("Cohorts") }

      before do
        (2026..2028).map { create :cohort, start_year: _1 }
      end

      it "the first entry is 'All cohorts'" do
        expect(subject.first.name).to eql("All cohorts")
      end

      it "has an entry for each cohort" do
        expect(subject.drop(1).map(&:name)).to eq([
          "Cohort 2028 to 2029",
          "Cohort 2027 to 2028",
          "Cohort 2026 to 2027",
        ])
      end
    end

    describe "Finance" do
      subject { instance.sub_structure("Finance") }

      it "the first entry is Statements" do
        expect(subject.first.name).to eql("Statements")
        expect(subject.first.href).to eql("/npq-separation/admin/finance/statements")
      end
    end
  end
end
