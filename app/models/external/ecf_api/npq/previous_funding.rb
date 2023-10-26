module External
  module EcfApi
    module Npq
      class PreviousFunding < Base
        self.parser = RawParser

        def self.table_name
          "previous_funding"
        end

        # Abstracted so we can decide whether or not to send trn/get_an_identity_id
        def self.find_for(npq_course_identifier:, trn:, get_an_identity_id:)
          params = {
            npq_course_identifier:,
          }
          params[:trn] = trn if trn.present?
          params[:get_an_identity_id] = get_an_identity_id if get_an_identity_id.present?

          with_params(params).find
        end
      end
    end
  end
end
