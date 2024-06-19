# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeclarationDateValidator do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      include ActiveModel::Attributes

      attribute :declaration_date, :datetime
      attr_reader :raw_declaration_date

      validates :declaration_date, declaration_date: true

      def declaration_date=(raw_date)
        self.raw_declaration_date = raw_date
        super
      end

      def schedule
        Schedule.new
      end

    private

      attr_writer :raw_declaration_date
    end
  end

  let(:declaration_date) { Date.new(2022, 1, 30) }
  let(:schedule_applies_from_date) { declaration_date - 1.day }
  let(:schedule_applies_to_date) { declaration_date + 1.day }

  subject { model_class.new(declaration_date: declaration_date.rfc3339) }

  before do
    allow_any_instance_of(Schedule).to receive(:applies_from).and_return(schedule_applies_from_date)
    allow_any_instance_of(Schedule).to receive(:applies_to).and_return(schedule_applies_to_date)
  end

  describe "#declaration_date" do
    describe "the declaration date has the right format" do
      context "when the declaration date is empty" do
        subject { model_class.new(declaration_date: "") }

        it "does not errors when the declaration date is blank" do
          expect(subject).to be_valid
        end
      end

      context "when declaration date format is invalid" do
        subject { model_class.new(declaration_date: "2021-06-21 08:46:29") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
        end
      end

      context "when declaration date is invalid" do
        subject { model_class.new(declaration_date: "2023-19-01T11:21:55Z") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
        end
      end

      context "when declaration time is invalid" do
        subject { model_class.new(declaration_date: "2023-19-01T29:21:55Z") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
        end
      end
    end

    describe "declaration_date is within milestone" do
      context "when before the milestone start" do
        let(:schedule_applies_from_date) { declaration_date + 1.day }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:declaration_date)).to eq(["Enter a '#/declaration_date' that's on or after the milestone start."])
        end
      end

      context "when at the milestone start" do
        let(:schedule_applies_from_date) { declaration_date }

        it { is_expected.to be_valid }
      end

      context "when in the middle of milestone" do
        it { is_expected.to be_valid }
      end

      context "when at the milestone end" do
        let(:schedule_applies_to_date) { declaration_date }

        it { is_expected.to be_valid }
      end

      context "when after the milestone start" do
        let(:schedule_applies_to_date) { declaration_date - 1.day }

        it "has a meaningfull error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:declaration_date))
            .to eq(["Enter a '#/declaration_date' that's before the milestone end date."])
        end
      end
    end
  end
end
