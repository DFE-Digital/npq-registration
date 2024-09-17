# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a disableable model" do
  describe "scopes" do
    let!(:enabled_instance) { create(described_class.name.underscore) }
    let!(:disabled_instance) { create(described_class.name.underscore, :disabled) }

    describe "default_scope" do
      subject { described_class.all }

      it { is_expected.to include(enabled_instance) }
      it { is_expected.not_to include(disabled_instance) }
    end

    describe ".including_disabled" do
      subject { described_class.including_disabled }

      it { is_expected.to include(enabled_instance, disabled_instance) }
    end
  end
end
