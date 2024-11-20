# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeTrainingStatus, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted) }

  describe "#change_training_status" do
    context "with valid update" do
      before { service.training_status = "deferred" }

      it "updates training status" do
        expect { service.change_training_status }
          .to change { application.reload.training_status }.from("active").to("deferred")
      end

      it "adds an application state" do
        expect { service.change_training_status }
          .to change { application.application_states.where(state: :deferred).count }
                .from(0)
                .to(1)
      end
    end

    context "with invalid update" do
      it "does not update the status"
    end
  end
end
