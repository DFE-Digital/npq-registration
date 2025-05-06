module API
  module FilterByParticipantIds
    extend ActiveSupport::Concern

    UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  protected

    def participant_ids
      params.dig(:filter, :participant_id).tap do |ids|
        break if ids.blank?

        raise_participant_id_error unless ids.is_a?(String)

        ids.split(",").each do |id|
          raise_participant_id_error unless id.match?(UUID_FORMAT)
        end
      end
    end

    def raise_participant_id_error
      raise ActionController::BadRequest, I18n.t(:invalid_participant_id_filter)
    end
  end
end
