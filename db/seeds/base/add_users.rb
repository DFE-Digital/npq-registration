# frozen_string_literal: true

class SeedAddUsers
  def load
    # create some users that have been archived with blanked emails

    cohorts_with_teacher_auth_users = Cohort.where(start_year: 2025..)

    User
      .joins(applications: :cohort)
      .with_get_an_identity_id
      .where(cohort: { start_year: ..2025 })
      .where.not(email: nil)
      .order(id: :desc)
      .limit(40).each do |user|
      # archive the user and blank the email
      email = user.email
      full_name = user.full_name
      trn = user.trn
      Users::Archiver.new(user:).archive!(blank_email: true, notify_sentry: false)

      # create a new user with the same name, email address and an application
      FactoryBot.create(
        :application,
        :with_random_user,
        :with_random_work_setting,
        user: FactoryBot.create(:user, :with_random_name, :with_teacher_auth, :with_verified_trn, full_name:, email:, trn:),
        lead_provider_approval_status: "pending",
        cohort: cohorts_with_teacher_auth_users.sample,
      )
    end
  end
end
