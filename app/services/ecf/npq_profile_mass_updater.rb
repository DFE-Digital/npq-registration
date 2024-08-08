module Ecf
  class NpqProfileMassUpdater
    prepend Base

    def initialize(applications:, &after_save)
      @applications = applications
      @after_save = after_save
    end

    def call
      applications.find_each.with_index do |application, i|
        sleep(0.1) # Ensure that ECF API is not overloaded

        Rails.logger.info "syncing application #{application.id}, (#{i + 1}/#{count})"

        Ecf::NpqProfileUpdater.new(application:).call

        after_save.call(application) if after_save.present?
      rescue StandardError => e
        Rails.logger.info "error with application #{application.id}: #{e.message}"
        errored_ids << application.id
      end

      Rails.logger.info "done"

      Rails.logger.info "errored applications: #{errored_ids}"
    end

  private

    attr_reader :applications, :after_save

    def errored_ids
      @errored_ids ||= []
    end

    def count
      applications.count
    end
  end
end
