namespace :one_off do
  desc "Setup some test data in Sandbox"
  task :sandbox_test_data_2026, %i[dry_run] => :versioned_environment do |_t, args|
    raise "Wrong environment" unless Rails.env.local? || Rails.env.sandbox? || Rails.env.review?

    dry_run = args[:dry_run] != "false"
    records_to_create = Rails.env.test? ? 3 : 10
    show_report = !Rails.env.test?

    # Don't send emails out
    unless Rails.env.test?
      Rails.configuration.action_mailer.delivery_method = :test
      Rails.configuration.action_mailer.perform_deliveries = false
      ActionMailer::Base.descendants.each { |mailer| mailer.perform_deliveries = false }
    end

    next_trn = User.maximum(:trn).to_i + 100

    Cohort.transaction do
      twentythree = Cohort.find_by!(identifier: "2023a")

      twentyfive = Cohort.create!(start_year: 2025,
                                  suffix: "b",
                                  funding: "capped",
                                  registration_start_date: "2025-09-01",
                                  description: "2025 Autumn")

      # Setup / update cohorts
      spring = Cohort.find_by!(identifier: "2026a")
      spring.update_attribute!(:funding, "zero") # bypass validation
      spring.update_attribute!(:registration_start_date, "2026-06-01") # bypass validation

      autumn = Cohort.find_by!(identifier: "2026b")
      autumn.update_attribute!(:funding, "capped") # bypass validation
      autumn.update_attribute!(:registration_start_date, "2026-06-01") # bypass validation

      # Setup schedules
      {
        [twentyfive, 9] => %w[npq_ehco_november npq_ehco_december npq_leadership_autumn npq_specialist_autumn],
        [spring, 10] => %w[npq_ehco_march npq_ehco_june npq_leadership_spring npq_specialist_spring],
        [autumn, 11] => %w[npq_ehco_november npq_ehco_december npq_leadership_autumn npq_specialist_autumn],
      }.each do |(cohort, policy_descriptor), identifiers|
        identifiers.each do |schedule_identifier|
          existing = cohort.schedules.find { |s| s.identifier == schedule_identifier.dasherize }

          if existing
            existing.update_columns(
              acceptance_window_start: Date.new(cohort.start_year, 1, 1),
              acceptance_window_end: Date.new(cohort.start_year, 12, 31),
            )
          else
            FactoryBot.create(
              :schedule,
              schedule_identifier,
              cohort:,
              change_applies_dates: false,
              policy_descriptor: policy_descriptor + (cohort.start_year - 2025),
              acceptance_window_start: Date.new(cohort.start_year, 1, 1),
              acceptance_window_end: Date.new(cohort.start_year, 12, 31),
            )
          end
        end
      end

      # Configure courses offered
      spring_csv = "db/seeds/data/unfunded_spring_2026a_course_cohort_providers.csv"
      CourseCohortProviders::Updater.new(cohort: spring, course_to_provider_csv: spring_csv, dry_run: false).call

      autumn_csv = "db/seeds/data/default_course_cohort_providers.csv"
      CourseCohortProviders::Updater.new(cohort: autumn, course_to_provider_csv: autumn_csv, dry_run: false).call

      all_courses = autumn.courses.to_a
      spring_courses = spring.courses.to_a

      # Setup Users and Applications
      LeadProvider.all.find_each do |lead_provider|
        if show_report
          puts "=" * 40
          puts lead_provider.name
          puts "#{"=" * 40}\n\n"
        end

        # Sample user with null email address
        application = Application.where(cohort: twentythree, lead_provider:).order(:created_at).first
        if application
          old_email = application.user.email
          application.user.update!(email: nil, archived_at: Time.current, archived_email: old_email)

          puts "Nullified User Email: #{application.user.ecf_id}\n\n" if show_report
        end

        # 2025b Applications
        {}.tap do |ids|
          records_to_create.times do
            next_trn += 1
            trn = sprintf("%07d", next_trn)

            FactoryBot.create(:user, :with_get_an_identity_id, :with_verified_trn, trn:) do |user|
              ids[user.ecf_id] = FactoryBot.create(
                :application,
                :with_random_work_setting,
                lead_provider:,
                course: all_courses.sample,
                lead_provider_approval_status: "pending",
                cohort: twentyfive,
                user:,
              ).ecf_id
            end
          end

          if show_report
            puts "Autumn 2025 applications"
            puts "-" * 40
            ids.each { |uid, aid| puts "User #{uid} = Application #{aid}" }
            puts "\n"
          end
        end

        # 2026b Applications for users without TRNs
        {}.tap do |ids|
          records_to_create.times do
            FactoryBot.create(:user, :with_teacher_auth, :without_trn) do |user|
              ids[user.ecf_id] = FactoryBot.create(
                :application,
                :with_random_work_setting,
                lead_provider:,
                course: all_courses.sample,
                lead_provider_approval_status: "pending",
                cohort: autumn,
                user:,
              ).ecf_id
            end
          end

          if show_report
            puts "Autumn 2026 applications without TRNs"
            puts "-" * 40
            ids.each { |uid, aid| puts "User #{uid} = Application #{aid}" }
            puts "\n"
          end
        end

        # 2026b Applications for users with TRNs
        {}.tap do |ids|
          records_to_create.times do
            next_trn += 1
            trn = sprintf("%07d", next_trn)

            FactoryBot.create(:user, :with_teacher_auth, :with_verified_trn, :with_previous_names, trn:) do |user|
              ids[user.ecf_id] = FactoryBot.create(
                :application,
                :with_random_work_setting,
                lead_provider:,
                course: all_courses.sample,
                lead_provider_approval_status: "pending",
                cohort: autumn,
                user:,
              ).ecf_id
            end
          end

          if show_report
            puts "Autumn 2026 applications with TRNs and previous names"
            puts "-" * 40
            ids.each { |uid, aid| puts "User #{uid} = Application #{aid}" }
            puts "\n"
          end
        end

        next unless lead_provider.name.in? ["Best Practice Network", "LLSE"]

        {}.tap do |ids|
          records_to_create.times do
            next_trn += 1
            trn = sprintf("%07d", next_trn)

            FactoryBot.create(:user, :with_teacher_auth, :with_verified_trn, trn:) do |user|
              ids[user.ecf_id] = FactoryBot.create(
                :application,
                :with_random_work_setting,
                lead_provider:,
                course: spring_courses.sample,
                lead_provider_approval_status: "pending",
                cohort: spring,
                user:,
              ).ecf_id
            end
          end

          if show_report
            puts "Spring 2026 applications with TRNs"
            puts "-" * 40
            ids.each { |uid, aid| puts "User #{uid} = Application #{aid}" }
            puts "\n"
          end
        end
      end

      if dry_run
        puts "Dry run: rolling back" if show_report
        raise ActiveRecord::Rollback
      end
    end
  end
end
