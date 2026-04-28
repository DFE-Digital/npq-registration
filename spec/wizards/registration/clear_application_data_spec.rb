require "rails_helper"

RSpec.describe Registration::ClearApplicationData do
  let(:action) { described_class.new(repository:, step:) }
  let(:wizard) { create(:registration_wizard, :completed) }
  let(:repository) { wizard.state_store.repository }
  let(:step) { wizard.current_step }

  it "clears the repository" do
    expect { action.execute }
      .to change(wizard.state_store, :course_start_cohort).from("2026b").to(nil)
  end
end
