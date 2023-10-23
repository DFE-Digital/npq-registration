module LeadProviders
  class Updater
    class << self
      def call
        new.call
      end
    end

    def call
      ActiveRecord::Base.transaction do
        LeadProvider::ALL_PROVIDERS.each { |name, id| create_or_update_lead_provider(name, id) }
      rescue StandardError => e
        Rails.logger.error("Encountered error #{e.message}. Rolling back all changes")
        raise ActiveRecord::Rollback
      end
    end

  private

    def create_or_update_lead_provider(name, ecf_id)
      Rails.logger.info("Updating Lead Provider with ECF ID #{ecf_id} to use name #{name}")
      LeadProvider.find_or_initialize_by(ecf_id:).update!(name:)
    end
  end
end
