# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserOTPCodeValidator do
  subject(:model) { TestModel.new }

  let(:stored_code) { "ABCD2345" }
  let(:expires_at) { 5.minutes.from_now }
  let(:entered_code) { stored_code }
  let(:otp) { OTP.new(code: stored_code, expires_at:) }
  let(:user) { instance_double(Admin, otp:, otp_locked?: false) }

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

  context "when the user is locked" do
    let(:user) { instance_double(Admin, otp:, otp_locked?: true) }

    it "adds a locked error and does not check the code" do
      model.valid?
      expect(model.errors).to be_of_kind(:code, :locked)
      expect(model.errors).not_to be_of_kind(:code, :incorrect)
    end
  end

  context "when the user has no usable OTP" do
    let(:user) { instance_double(Admin, otp: nil, otp_locked?: false) }

    it "adds an incorrect error and does not raise" do
      expect { model.valid? }.not_to raise_error
      expect(model.errors).to be_of_kind(:code, :incorrect)
    end
  end
end
