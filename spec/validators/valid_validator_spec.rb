# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidValidator do
  before do
    stub_const("TestModel", Class.new).class_eval do
      include ActiveModel::Validations
      attr_accessor :model_attribute

      validates :model_attribute, valid: true

      def initialize(model_attribute:)
        @model_attribute = model_attribute
      end
    end

    stub_const("Model", Class.new).class_eval do
      include ActiveModel::Validations

      validates :valid, inclusion: { in: [true] }

      attr_accessor :valid

      def initialize(valid:)
        @valid = valid
      end
    end
  end

  subject { TestModel.new(model_attribute:) }

  context "when the model attribute is valid" do
    let(:model_attribute) { Model.new(valid: true) }

    it { is_expected.to be_valid }
  end

  context "when the model attribute is invalid" do
    let(:model_attribute) { Model.new(valid: false) }

    it "is not valid" do
      expect(subject).not_to be_valid
    end

    it "copies the errors from the model attribute" do
      subject.valid?
      expect(subject).to have_error(:valid, :inclusion, "is not included in the list")
    end
  end

  context "when the value is nil" do
    let(:model_attribute) { nil }

    it "is not valid" do
      expect(subject).to be_valid
    end
  end
end
