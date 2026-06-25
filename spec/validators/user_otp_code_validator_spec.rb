# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserOTPCodeValidator do
  subject(:model) { TestModel.new }

  let(:stored_code) { "ABCD2345" }
  let(:expires_at) { 5.minutes.from_now }
  let(:entered_code) { stored_code }
  let(:user) { instance_double(Admin, otp_hash: stored_code, otp_expires_at: expires_at) }

  before do
    stub_const("TestModel", Class.new).class_eval do
      include ActiveModel::Validations
      attr_accessor :code, :user

      validates :code, user_otp_code: true
    end

    model.code = entered_code
    model.user = user
  end

  it "is valid when the code matches and has not expired" do
    expect(model).to be_valid
  end

  it "is valid when the code matches in lower case" do
    model.code = entered_code.downcase
    expect(model).to be_valid
  end

  context "when the code matches but has expired" do
    let(:expires_at) { 1.minute.ago }

    it "adds an expired error" do
      model.valid?
      expect(model.errors).to be_of_kind(:code, :expired)
    end
  end

  context "when the code does not match" do
    let(:entered_code) { "WXYZ6789" }

    it "adds an incorrect error" do
      model.valid?
      expect(model.errors).to be_of_kind(:code, :incorrect)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "adds an incorrect error and does not raise" do
      expect { model.valid? }.not_to raise_error
      expect(model.errors).to be_of_kind(:code, :incorrect)
    end
  end

  context "when the stored code is not a valid OTP" do
    let(:user) { instance_double(Admin, otp_hash: "123456", otp_expires_at: expires_at) }

    it "adds an incorrect error and does not raise" do
      expect { model.valid? }.not_to raise_error
      expect(model.errors).to be_of_kind(:code, :incorrect)
    end
  end

  context "when the stored expiry is missing" do
    let(:user) { instance_double(Admin, otp_hash: stored_code, otp_expires_at: nil) }

    it "adds an incorrect error and does not raise" do
      expect { model.valid? }.not_to raise_error
      expect(model.errors).to be_of_kind(:code, :incorrect)
    end
  end
end
