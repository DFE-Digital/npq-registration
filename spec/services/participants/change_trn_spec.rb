# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::ChangeTrn, type: :model do
  subject { described_class.new(trn: trn, user: user) }

  let(:user) { create(:user, :with_verified_trn, trn: original_trn) }
  let(:original_trn) { "1234567" }
  let(:trn) { "2345678" }

  describe "validations" do
    it "does not allow a blank TRN" do
      expect(subject).to validate_presence_of(:trn).with_message(:blank).with_message("TRN can't be blank")
    end

    it "does not allow forbidden TRNs" do
      expect(subject).not_to allow_value("0000000").for(:trn).with_message("You must enter a valid TRN")
    end

    it "does not allow non-numeric characters" do
      expect(subject).not_to allow_value("AA99/12345").for(:trn).with_message("TRN must only contain numbers")
    end

    it "does not allow less than 7 characters" do
      expect(subject).not_to allow_value("1234").for(:trn).with_message("TRN is the wrong length (should be 7 characters)")
    end

    it "does not allow more than 7 characters" do
      expect(subject).not_to allow_value("99123456").for(:trn).with_message("TRN is the wrong length (should be 7 characters)")
    end

    it "does not allow a nil user" do
      expect(subject).not_to allow_value(nil).for(:user).with_message("User not found")
    end
  end

  describe "#change_trn" do
    subject { described_class.new(trn: trn, user: user).change_trn }

    it "updates the user's TRN" do
      expect { subject }.to change(user, :trn).from(original_trn).to(trn)
    end

    context "when the TRN has whitespace" do
      let(:trn) { "  2345  678  " }

      it "strips whitespace" do
        expect { subject }.to change(user, :trn).from(original_trn).to("2345678")
      end
    end

    context "when the the TRN is blank" do
      let(:trn) { "" }

      it "does not update the TRN" do
        expect { subject }.not_to change(user, :trn)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when the user is nil" do
      let(:user) { nil }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when trn_verified is false" do
      let(:user) { create(:user, trn: original_trn) }

      it "updates trn_verified to true" do
        expect { subject }.to change(user, :trn_verified).from(false).to(true)
      end
    end
  end
end
