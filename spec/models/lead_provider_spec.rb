require "rails_helper"

RSpec.describe LeadProvider do
  describe "#for" do
    subject { described_class.for(course:).map(&:name) }

    let(:course) { Course.find_by!(identifier: course_identifier) }

    before do
      LeadProviders::Updater.call
    end

    context "with course npq-headship" do
      let(:course_identifier) { "npq-headship" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-senior-leadership" do
      let(:course_identifier) { "npq-senior-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-teaching" do
      let(:course_identifier) { "npq-leading-teaching" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-teaching-development" do
      let(:course_identifier) { "npq-leading-teaching-development" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-behaviour-culture" do
      let(:course_identifier) { "npq-leading-behaviour-culture" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-early-headship-coaching-offer" do
      let(:course_identifier) { "npq-early-headship-coaching-offer" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-additional-support-offer" do
      let(:course_identifier) { "npq-additional-support-offer" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-early-years-leadership" do
      let(:course_identifier) { "npq-early-years-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Education Development Trust",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-literacy" do
      let(:course_identifier) { "npq-leading-literacy" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Education Development Trust",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-executive-leadership" do
      let(:course_identifier) { "npq-executive-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end
  end
end
