namespace :sync do
  desc "Sync applications attributes with ecf service"
  task applications: :environment do
    Rails.logger.info "syncing applications"

    count = Application.count
    errored_ids = []
    Application.each_with_index do |application, i|
      Rails.logger.info "syncing application #{application.id}, (#{i + 1},/#{count})"
      Services::NpqProfileUpdater.new(application: application).call
    rescue StandardError
      Rails.logger.info "error with application #{application.id}"
      errored_ids << application.id
    end

    Rails.logger.info "done"

    Rails.logger.info "errored applications: #{errored_ids}"
  end
end
