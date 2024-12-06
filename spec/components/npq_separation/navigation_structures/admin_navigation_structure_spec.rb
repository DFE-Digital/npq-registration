require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::AdminNavigationStructure, type: :component do
  describe "#primary_structure" do
    subject { NpqSeparation::NavigationStructures::AdminNavigationStructure.new.primary_structure }

    {
      "Dashboard" => "/npq-separation/admin",
      "Applications" => "/npq-separation/admin/applications",
      "Cohorts" => "/npq-separation/admin/cohorts",
      "Courses" => "/npq-separation/admin/courses",
      "Participants" => "/npq-separation/admin/users",
      "Finance" => "/npq-separation/admin/finance/statements",
      "Schools" => "/npq-separation/admin/schools",
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
    describe "Cohorts" do
      subject { NpqSeparation::NavigationStructures::AdminNavigationStructure.new.sub_structure("Cohorts") }

      before do
        (2026..2028).map { create :cohort, start_year: _1 }
      end

      it "the first entry is 'All cohorts'" do
        expect(subject.first.name).to eql("All cohorts")
      end

      it "has an entry for each cohort" do
        expect(subject.drop(1).map(&:name)).to eq([
          "Cohort 2028/29",
          "Cohort 2027/28",
          "Cohort 2026/27",
        ])
      end
    end

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
