require "rails_helper"

RSpec.describe Admin::NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

    expected_structure =
      {
        "Dashboards" => "/admin",
        "Applications" => "/admin/applications",
        "Cohorts" => "/admin/cohorts",
        "Courses" => "/admin/courses",
        "Users" => "/admin/users",
        "Finance" => "/admin/finance/statements",
        "Workplaces" => "/admin/schools",
        "Providers" => "/admin/providers",
        "Delivery partners" => "/admin/delivery-partners",
        "Bulk changes" => "/admin/bulk-changes",
        "Webhook messages" => "/admin/webhook-messages",
        "Registration closed" => "/admin/registration-closed",
        "Actions log" => "/admin/actions-log",
        "Glossary" => "/admin/glossary",
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
        expect(subject[-3]).to have_attributes(name: "Feature flags")
        expect(subject[-3]).to have_attributes(href: "/admin/features")
      end

      it "includes admins" do
        expect(subject[-2]).to have_attributes(name: "Admins")
        expect(subject[-2]).to have_attributes(href: "/admin/admins")
      end
    end
  end

  describe "#sub_structure" do
    describe "Dashboards" do
      subject { instance.sub_structure("/admin/dashboards") }

      it "the first entry is Courses dashboard" do
        expect(subject.first.name).to eql("Courses dashboard")
        expect(subject.first.href).to eql("/admin/dashboards/courses-dashboard")
      end

      it "the second entry is Providers dashboard" do
        expect(subject.second.name).to eql("Providers dashboard")
        expect(subject.second.href).to eql("/admin/dashboards/providers-dashboard")
      end
    end
  end
end
