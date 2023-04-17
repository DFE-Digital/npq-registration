module Services
  module GetAnIdentity
    module Webhooks
      class UserUpdatedProcessor
        class << self
          def call(webhook_message:)
            new(webhook_message:).call
          end
        end

        attr_reader :webhook_message

        def initialize(webhook_message:)
          @webhook_message = webhook_message
        end

        def call
          return wrong_processor_failure unless webhook_message.message_type == "UserUpdated"
          return no_user_found_failure if user.blank?

          if user.updated_from_tra_at.present? && user.updated_from_tra_at > webhook_message.sent_at
            return more_recent_data_recorded_success
          end

          if user.update(update_params)
            sync_user_changes_to_ecf
            webhook_message.processed!
          else
            record_error(user.errors.full_messages.join(", "))
          end
        rescue StandardError => e
          record_error([e.class, e.message].join(": "))
        end

      private

        delegate :decorated_message, to: :webhook_message

        def record_error(message)
          webhook_message.update!(
            status: :failed,
            status_comment: message,
            processed_at: Time.zone.now,
          )
          false
        end

        def wrong_processor_failure
          record_error("Wrong processor used for message type: #{webhook_message.message_type}")
        end

        def no_user_found_failure
          record_error("No user found with get_an_identity_id: #{decorated_message.uid}")
        end

        def more_recent_data_recorded_success
          webhook_message.update!(
            status: :processed,
            status_comment: "More recent data recorded",
            processed_at: Time.zone.now,
          )
          true
        end

        def user
          @user ||= User.find_by_get_an_identity_id(decorated_message.uid)
        end

        def update_params
          {
            full_name: decorated_message.full_name,
            date_of_birth: decorated_message.date_of_birth,
            trn: decorated_message.trn,
            trn_verified: decorated_message.trn_verified,
            trn_lookup_status: decorated_message.trn_lookup_status,
            email: decorated_message.email,
            updated_from_tra_at: decorated_message.sent_at,
          }
        end

        def sync_user_changes_to_ecf
          Services::Ecf::EcfUserUpdater.call(user:)
        end
      end
    end
  end
end
