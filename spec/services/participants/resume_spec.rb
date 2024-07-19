# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Resume, type: :model do
  it_behaves_like "a participant action" do
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:) }
    let(:application) { create(:application, :accepted, :with_declaration, training_status: %w[withdrawn deferred].sample) }
  end

  it_behaves_like "a participant state transition", :resume, %w[withdrawn deferred], "active" do
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:) }

    describe "validations" do
      context "when the application is already active" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant, :already_active, "The participant is already active") }
      end
    end
  end
end
