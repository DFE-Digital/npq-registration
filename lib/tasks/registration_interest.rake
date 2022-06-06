namespace :registration_interest do
  desc "Send notifications to users indicating NPQ applications are open"
  task :send_notifications, %i[count] => :environment do |_t, args|
    count = args["count"].to_i

    RegistrationInterest.not_yet_notified.random_sample(count).each do |registration_interest|
      RegistrationOpenNotificationJob.perform_later(registration_interest: registration_interest)
    end
  end
end
