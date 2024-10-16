module Migration::ParityCheck
  class TokenProvider
    class UnsupportedEnvironmentError < RuntimeError; end

    def generate!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      LeadProvider.all.each_with_object({}) do |lead_provider, hash|
        hash[lead_provider.ecf_id] = {
          ecf: generate_ecf_token!(lead_provider),
          npq: generate_npq_token!(lead_provider),
        }
      end
    end

  private

    def generate_ecf_token!(lead_provider)
      cpd_lead_provider = Migration::Ecf::NpqLeadProvider.find(lead_provider.ecf_id).cpd_lead_provider
      Migration::Ecf::LeadProviderAPIToken.create_with_random_token!(cpd_lead_provider:)
    end

    def generate_npq_token!(lead_provider)
      APIToken.create_with_random_token!(lead_provider:)
    end

    def enabled?
      Rails.application.config.npq_separation[:parity_check][:enabled]
    end
  end
end
