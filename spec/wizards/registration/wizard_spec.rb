require "rails_helper"

RSpec.describe Registration::Wizard do
  subject { create :registration_wizard, current_step:, current_user:, state: }

  let(:current_step) { :start }
  let(:current_user) { nil }
  let(:state) { {} }

  it { is_expected.to have_root_step(:start) }
  it { is_expected.to have_next_step(:course_start_date).from(:start) }
  it { is_expected.to have_next_step(:check_answers).from(:course_start_date).when(course_start_date: nil) }
  it { is_expected.to have_next_step(:check_answers).from(:course_start_date).when(course_start_date: "yes") }
  it { is_expected.to have_next_step(:cannot_register_yet).from(:course_start_date).when(course_start_date: "no") }
  it { is_expected.to have_next_step(:applications_list).from(:check_answers) }

  describe "paths to end of journey" do
    let(:current_step) { :check_answers }
    let(:current_user) { build_stubbed(:user) }

    context "when just started" do
      let(:state) { { started: true } }

      it { is_expected.to have_flow_path(%i[start course_start_date check_answers]) }
      it { is_expected.to have_valid_path(%i[start]) }
    end

    context "when yes at course_start_date" do
      let(:state) { { started: true, course_start_date: "yes" } }

      it { is_expected.to have_flow_path(%i[start course_start_date check_answers]) }
      it { is_expected.to have_valid_path(%i[start course_start_date check_answers]) }
    end

    context "when no at course_start_date" do
      let(:state) { { started: true, course_start_date: "no" } }

      context "with path to check_answers screen" do
        it { is_expected.to have_flow_path(%i[]) }
        it { is_expected.to have_valid_path(%i[]) }
      end

      context "with path to early exit screen" do
        let(:current_step) { :cannot_register_yet }

        it { is_expected.to have_flow_path(%i[start course_start_date cannot_register_yet]) }
        it { is_expected.to have_valid_path(%i[start course_start_date cannot_register_yet]) }
      end
    end
  end

  describe "reaching end of journey and clearing state" do
    let(:wizard) { create(:registration_wizard, :completed) }

    it "clears the state upon completion" do
      expect { wizard.save_current_step }
        .to change(wizard.state_store, :started).from(true).to(nil)
    end
  end
end
