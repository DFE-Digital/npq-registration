require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

    expected_structure =
      {
        "Dashboards" => "/npq-separation/admin",
        "Applications" => "/npq-separation/admin/applications",
        "Cohorts" => "/npq-separation/admin/cohorts",
        "Courses" => "/npq-separation/admin/courses",
        "Users" => "/npq-separation/admin/users",
        "Finance" => "/npq-separation/admin/finance/statements",
        "Workplaces" => "/npq-separation/admin/schools",
        "Providers" => "/npq-separation/admin/providers",
        "Delivery partners" => "/npq-separation/admin/delivery-partners",
        "Bulk changes" => "/npq-separation/admin/bulk-changes",
        "Webhook messages" => "/npq-separation/admin/webhook-messages",
        "Registration closed" => "/npq-separation/admin/registration-closed",
        "Actions log" => "/npq-separation/admin/actions-log",
      }
    expected_structure.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end

    it "has the expected number of items" do
      expect(subject.size).to eql(expected_structure.size)
    end

    it "excludes feature flags" do
      expect(subject.map(&:name)).not_to include("Feature flags")
    end

    context "when user is a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

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
    describe "Dashboards" do
      subject { instance.sub_structure("Dashboards") }

      it "the first entry is Courses dashboard" do
        expect(subject.first.name).to eql("Courses dashboard")
        expect(subject.first.href).to eql("/npq-separation/admin/dashboards/courses-dashboard")
      end

      it "the second entry is Providers dashboard" do
        expect(subject.second.name).to eql("Providers dashboard")
        expect(subject.second.href).to eql("/npq-separation/admin/dashboards/providers-dashboard")
      end
    end
  end
end
