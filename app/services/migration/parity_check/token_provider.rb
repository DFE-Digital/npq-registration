module Migration
  class ParityCheck::TokenProvider
    class UnsupportedEnvironmentError < RuntimeError; end

    def generate!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      known_tokens_by_lead_provider_ecf_id.each do |ecf_id, token|
        lead_provider = LeadProvider.find_by!(ecf_id:)
        create_with_known_token!(token:, lead_provider:) if lead_provider
      end
    end

    def token(lead_provider:)
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      known_tokens_by_lead_provider_ecf_id[lead_provider.ecf_id]
    end

  private

    def known_tokens_by_lead_provider_ecf_id
      JSON.parse(ENV["PARITY_CHECK_KEYS"].to_s)
    rescue JSON::ParserError
      {}
    end

    def create_with_known_token!(token:, lead_provider:)
      APIToken.create_with_known_token!(token, lead_provider:)
    end

    def enabled?
      Rails.application.config.npq_separation[:parity_check][:enabled]
    end
  end
end
