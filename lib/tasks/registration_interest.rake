namespace :registration_interest do
  desc "Send notifications to users indicating NPQ applications are open"
  task :send_notifications, %i[count] => :environment do |_t, args|
    count = args["count"]

    recipients = if count == "all"
                   RegistrationInterest.not_yet_notified
                 else
                   count = count.to_i
                   RegistrationInterest.not_yet_notified.random_sample(count)
                 end

    puts("Sending registration opening notification to #{recipients.count} unnotified registered emails")

    recipients.each do |registration_interest|
      RegistrationOpenNotificationJob.perform_later(registration_interest: registration_interest)
    end
  end
end
