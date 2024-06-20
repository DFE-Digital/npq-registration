# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Resume, type: :model do
  it_behaves_like "a participant action", :resume, %w[withdrawn deferred], "active" do
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:) }

    describe "validations" do
      context "when the application is already active" do
        let(:application) { create(:application, :accepted) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_active)
        end
      end
    end
  end
end
