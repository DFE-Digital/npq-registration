# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseForParticipantValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :course_identifier, course_for_participant: true

      attr_reader :participant, :course_identifier

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(participant:, course_identifier:)
        @participant = participant
        @course_identifier = course_identifier
      end
    end
  end

  describe "#validate" do
    let(:application) { create(:application, :accepted) }
    let(:participant) { application.user }

    subject { klass.new(participant:, course_identifier:) }

    context "with a valid course" do
      let(:course_identifier) { application.course.identifier }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with an invalid course" do
      let(:course_identifier) { "incorrect-course-identifier" }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has a meaningfull error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.first).to have_attributes(attribute: :course_identifier, type: :invalid)
      end
    end

    context "when application has not been accepted yet" do
      let(:application) { create(:application) }
      let(:participant) { application.user }
      let(:course_identifier) { application.course.identifier }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has a meaningfull error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.first).to have_attributes(attribute: :course_identifier, type: :invalid)
      end
    end
  end
end
