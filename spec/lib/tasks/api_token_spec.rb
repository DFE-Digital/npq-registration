require "rails_helper"

RSpec.describe "API Token tasks" do
  before { allow(Rails.logger).to receive(:info).and_call_original }

  describe "api_token:teacher_record_service:generate_token" do
    subject(:run_task) { Rake::Task["api_token:teacher_record_service:generate_token"].invoke }

    after do
      Rake::Task["api_token:teacher_record_service:generate_token"].reenable
    end

    let(:api_tokens) { APIToken.where(scope: APIToken.scopes[:teacher_record_service]) }

    it "creates a new API token for the Teacher Record Service" do
      expect { run_task }.to change(api_tokens, :count).by(1)
    end

    it "outputs the unhashed version of the new API Token" do
      run_task

      expect(Rails.logger).to have_received(:info).with(/\AAPI Token created: [\w-]+\z/)
    end
  end

  describe "api_token:lead_provider:generate_token" do
    subject :run_task do
      Rake::Task["api_token:lead_provider:generate_token"].invoke(lead_provider_id)
    end

    after do
      Rake::Task["api_token:lead_provider:generate_token"].reenable
    end

    context "without lead_provider_id" do
      let(:lead_provider_id) { nil }

      it "errors and does not create token" do
        expect { run_task }
          .to raise_exception(RuntimeError, "Unknown lead_provider_id")
                .and(not_change(APIToken, :count))
      end
    end

    context "with unknown lead provider_id" do
      let(:lead_provider_id) { 99 }

      it "errors and does not create token" do
        expect { run_task }
          .to raise_exception(RuntimeError, "Unknown lead_provider_id")
                .and(not_change(APIToken, :count))
      end
    end

    context "with known lead_provider_id" do
      let(:api_tokens) { APIToken.where(scope: "lead_provider", lead_provider_id:) }
      let(:lead_provider_id) { create(:lead_provider).id }

      it "creates a new API Token for the lead provider" do
        expect { run_task }.to change(api_tokens, :count).by(1)
      end

      it "outputs the unhashed version of the new API Token" do
        run_task

        expect(Rails.logger).to have_received(:info).with(/\AAPI Token created: [\w-]+\z/)
      end
    end
  end
end
