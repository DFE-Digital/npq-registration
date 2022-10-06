require "rails_helper"

RSpec.describe LeadProvider do
  describe "#for" do
    subject { described_class.for(course:).map(&:name) }

    let(:course) { Course.find_by!(name: course_name) }

    before do
      Services::LeadProviders::Updater.call
    end

    context "with course #{Course::COURSE_NAMES[:NPQH]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQH] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQSL]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQSL] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQLT]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQLT] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQLTD]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQLTD] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQLBC]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQLBC] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:EHCO]}" do
      let(:course_name) { Course::COURSE_NAMES[:EHCO] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:ASO]}" do
      let(:course_name) { Course::COURSE_NAMES[:ASO] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "Education Development Trust",
          "LLSE",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQEYL]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQEYL] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Education Development Trust",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQLL]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQLL] }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Education Development Trust",
          "National Institute of Teaching",
          "School-Led Network",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course #{Course::COURSE_NAMES[:NPQEL]}" do
      let(:course_name) { Course::COURSE_NAMES[:NPQEL] }

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
