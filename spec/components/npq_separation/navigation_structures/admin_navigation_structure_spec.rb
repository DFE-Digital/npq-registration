require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

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
        expect(subject[-3]).to have_attributes(name: "Registration closed")
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
end
