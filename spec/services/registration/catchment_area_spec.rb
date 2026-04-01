require "rails_helper"

RSpec.describe Registration::CatchmentArea do
  subject(:catchment) { described_class.new(teacher_catchment:, country_name:) }

  before { allow(Sentry).to receive(:capture_message).and_call_original }

  let(:uk_country) { "United Kingdom of Great Britain and Northern Ireland" }
  let(:iso_code) { catchment.teacher_catchment_iso_country_code }

  context "with England" do
    let(:teacher_catchment) { "england" }
    let(:country_name) { nil }

    it { is_expected.to have_attributes teacher_catchment_country: uk_country }
    it { is_expected.to have_attributes teacher_catchment_iso_country_code: "GBR" }

    describe "Sentry warning" do
      before { catchment.teacher_catchment_iso_country_code }

      it { expect(Sentry).not_to have_received :capture_message }
    end
  end

  context "with Other country" do
    let(:teacher_catchment) { "another" }
    let(:country_name) { "France" }

    it { is_expected.to have_attributes teacher_catchment_country: "France" }
    it { is_expected.to have_attributes teacher_catchment_iso_country_code: "FRA" }

    describe "Sentry warning" do
      before { catchment.teacher_catchment_iso_country_code }

      it { expect(Sentry).not_to have_received :capture_message }
    end
  end

  context "with unknown country" do
    let(:teacher_catchment) { "another" }
    let(:country_name) { "Unknown" }

    it { is_expected.to have_attributes teacher_catchment_country: "Unknown" }
    it { is_expected.to have_attributes teacher_catchment_iso_country_code: nil }

    describe "Sentry warning" do
      before { catchment.teacher_catchment_iso_country_code }

      it { expect(Sentry).to have_received :capture_message }
    end
  end
end
