module TeachingRecordSystem
  class UpdateUserAttributesJob < ApplicationJob
    discard_on StandardError do |_job, exception|
      Sentry.capture_exception(exception)
    end

    def perform(user_id:, access_token:)
      user = User.find(user_id)
      return unless user.verified_trn

      trs_person = TeachingRecordSystem::FetchPerson.fetch(access_token:)
      user.update!(previous_names: trs_person.previous_names)
    end
  end
end
