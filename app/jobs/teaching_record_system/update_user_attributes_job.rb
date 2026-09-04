module TeachingRecordSystem
  class UpdateUserAttributesJob < ApplicationJob
    discard_on StandardError do |_job, exception|
      Sentry.capture_exception(exception)
    end

    def perform(user_id:)
      user = User.find(user_id)
      token = user.access_token
      return unless token

      token.destroy!
      return unless user.verified_trn

      trs_person = TeachingRecordSystem::FetchPerson.fetch(access_token: token.token)
      user.previous_names = trs_person.previous_names
      user.save!
    end
  end
end
