# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "coping with an expired or non-existent session" do
  context "when the session has expired or does not exist" do
    let(:current_user) { NullUser.new }

    it "does not raise an error" do
      expect { subject.after_save }.not_to raise_error
    end
  end
end
