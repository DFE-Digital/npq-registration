require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::AdminNavigationStructure, type: :component do
  describe "#primary_structure" do
    subject { NpqSeparation::NavigationStructures::AdminNavigationStructure.new.primary_structure }

    {
      "Dashboard" => "/npq-separation/admin",
      "Applications" => "/npq-separation/admin/applications",
      "Finance" => "/npq-separation/admin/finance/statements",
      "Schools" => "#",
      "Lead providers" => "/npq-separation/admin/lead-providers",
      "Settings" => "#",
    }.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end
  end

  describe "#sub_structure" do
    describe "Finance" do
      subject { NpqSeparation::NavigationStructures::AdminNavigationStructure.new.sub_structure("Finance") }

      it "the first entry is Statements" do
        expect(subject.first.name).to eql("Statements")
        expect(subject.first.href).to eql("/npq-separation/admin/finance/statements")
      end

      describe "Statements sub pages" do
        {
          "Unpaid statements" => "/npq-separation/admin/finance/statements/unpaid",
          "Paid statements" => "/npq-separation/admin/finance/statements/paid",
        }.each_with_index do |(name, href), i|
          it "#{name} with href #{href} is at position #{i + 1}" do
            expect(subject.first.nodes[i].name).to eql(name)
            expect(subject.first.nodes[i].href).to eql(href)
          end
        end
      end
    end
  end
end
