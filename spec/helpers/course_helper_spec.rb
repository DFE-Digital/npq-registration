require "rails_helper"

RSpec.describe CourseHelper, type: :helper do
  describe ".localise_course_name" do
    let(:expected_results) do
      {
        "npq-leading-teaching" => "Leading teaching",
        "npq-leading-behaviour-culture" => "Leading behaviour and culture",
        "npq-leading-teaching-development" => "Leading teacher development",
        "npq-senior-leadership" => "Senior leadership",
        "npq-headship" => "Headship",
        "npq-executive-leadership" => "Executive leadership",
        "npq-additional-support-offer" => "Additional Support Offer",
        "npq-early-headship-coaching-offer" => "Early headship coaching offer",
        "npq-early-years-leadership" => "Early years leadership",
        "npq-leading-literacy" => "Leading literacy",
        "npq-leading-primary-mathematics" => "Leading primary mathematics",
        "npq-senco" => "Special educational needs co-ordinator (SENCO)",
      }
    end

    Course::IDENTIFIERS.each do |identifier|
      specify identifier.to_s do
        expected_result = expected_results[identifier]
        course = Course.find_by(identifier:)
        expect(helper.localise_course_name(course)).to eq(expected_result)
      end
    end
  end

  describe ".localise_sentence_embedded_course_name" do
    let(:expected_results) do
      {
        "npq-leading-teaching" => "the Leading teaching NPQ",
        "npq-leading-behaviour-culture" => "the Leading behaviour and culture NPQ",
        "npq-leading-teaching-development" => "the Leading teacher development NPQ",
        "npq-senior-leadership" => "the Senior leadership NPQ",
        "npq-headship" => "the Headship NPQ",
        "npq-executive-leadership" => "the Executive leadership NPQ",
        "npq-additional-support-offer" => "the Additional Support Offer NPQ",
        "npq-early-headship-coaching-offer" => "the Early headship coaching offer",
        "npq-early-years-leadership" => "the Early years leadership NPQ",
        "npq-leading-literacy" => "the Leading literacy NPQ",
        "npq-leading-primary-mathematics" => "the Leading primary mathematics NPQ",
        "npq-senco" => "the Special educational needs co-ordinator (SENCO) NPQ",
      }
    end

    Course::IDENTIFIERS.each do |identifier|
      specify identifier.to_s do
        expected_result = expected_results[identifier]
        course = Course.find_by(identifier:)
        expect(helper.localise_sentence_embedded_course_name(course)).to eq(expected_result)
      end
    end
  end

  describe ".course_short_code" do
    let(:expected_results) do
      {
        "npq-additional-support-offer" => "ASO",
        "npq-leading-behaviour-culture" => "NPQLBC",
        "npq-leading-literacy" => "NPQLL",
        "npq-leading-teaching" => "NPQLT",
        "npq-leading-teaching-development" => "NPQLTD",
        "npq-senior-leadership" => "NPQSL",
        "npq-leading-primary-mathematics" => "NPQLPM",
        "npq-headship" => "NPQH",
        "npq-executive-leadership" => "NPQEL",
        "npq-early-years-leadership" => "NPQEYL",
        "npq-senco" => "NPQS",
        "npq-early-headship-coaching-offer" => "EHCO",
      }
    end

    Course::IDENTIFIERS.each do |identifier|
      specify identifier.to_s do
        expected_result = expected_results[identifier]
        course = Course.find_by(identifier:)
        expect(helper.course_short_code(course)).to eq(expected_result)
      end
    end
  end

  describe ".title_embedded_course_name" do
    let(:expected_results) do
      {
        "npq-additional-support-offer" => "Additional Support Offer NPQ",
        "npq-leading-behaviour-culture" => "Leading behaviour and culture NPQ",
        "npq-leading-literacy" => "Leading literacy NPQ",
        "npq-leading-teaching" => "Leading teaching NPQ",
        "npq-leading-teaching-development" => "Leading teacher development NPQ",
        "npq-senior-leadership" => "Senior leadership NPQ",
        "npq-leading-primary-mathematics" => "Leading primary mathematics NPQ",
        "npq-headship" => "Headship NPQ",
        "npq-executive-leadership" => "Executive leadership NPQ",
        "npq-early-years-leadership" => "Early years leadership NPQ",
        "npq-senco" => "Special educational needs co-ordinator (SENCO) NPQ",
        "npq-early-headship-coaching-offer" => "Early headship coaching offer",
      }
    end

    Course::IDENTIFIERS.each do |identifier|
      specify identifier.to_s do
        expected_result = expected_results[identifier]
        course = Course.find_by(identifier:)
        expect(helper.title_embedded_course_name(course)).to eq(expected_result)
      end
    end
  end
end
