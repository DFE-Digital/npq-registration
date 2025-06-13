require "rails_helper"

RSpec.describe NpqSeparation::Admin::ApplicationNotesInputComponent, type: :component do
  subject { render_inline component }

  let(:component) { described_class.new(form:) }
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:form) { GOVUKDesignSystemFormBuilder::FormBuilder.new("application", application, template, {}) }

  let(:application) { create(:application) }

  it { is_expected.to have_css("textarea[name='application[notes]']") }

  context "when the application has notes" do
    let(:application) { create(:application, notes: "Existing note") }

    it { is_expected.to have_text("Edit the note about the changes to this registration") }
  end

  context "when the application does not have notes" do
    it { is_expected.to have_text("Add a note about the changes to this registration") }
  end
end
