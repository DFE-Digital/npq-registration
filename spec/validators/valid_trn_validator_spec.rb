# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTrnValidator do
  before do
    stub_const("TestModel", Class.new).class_eval do
      include ActiveModel::Validations
      attr_accessor :trn

      validates :trn, valid_trn: true
    end
  end

  subject { TestModel.new }

  it "allows a valid TRN" do
    subject.trn = "1234567"
    expect(subject).to be_valid
  end

  it "can only contain numbers" do
    subject.trn = "123456a"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN must only contain numbers"]
  end

  it "does not allow nil TRN" do
    subject.trn = nil
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN can't be blank"]
  end

  it "does not allow empty TRN" do
    subject.trn = ""
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN can't be blank"]
  end

  it "does not allow legacy style TRNs" do
    subject.trn = "RP99/12345"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN must only contain numbers"]
  end

  it "does not allow TRNs over 7 characters" do
    subject.trn = "99123456"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN is the wrong length (should be 7 characters)"]
  end

  it "does not allow TRNs under 7 characters" do
    subject.trn = "1234"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN is the wrong length (should be 7 characters)"]
  end

  it "does not allow TRNs with other letters" do
    subject.trn = "AA99/12345"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["TRN must only contain numbers"]
  end

  it "does not allow fake TRN 0000000" do
    subject.trn = "0000000"
    subject.valid?
    expect(subject.errors[:trn]).to eq ["You must enter a valid TRN"]
  end
end
