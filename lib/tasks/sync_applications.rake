namespace :sync do
  desc "Sync applications attributes with ecf service"
  task applications: :environment do
    Rails.logger.info "syncing applications"

    count = Application.where("ecf_id is not null").count
    errored_ids = []
    Application.where("ecf_id is not null").order(created_at: :asc).each_with_index do |application, i|
      sleep(0.1)
      Rails.logger.info "syncing application #{application.id}, (#{i + 1},/#{count})"
      Services::Ecf::NpqProfileUpdater.new(application:).call
    rescue StandardError
      Rails.logger.info "error with application #{application.id}"
      errored_ids << application.id
    end

    Rails.logger.info "done"

    Rails.logger.info "errored applications: #{errored_ids}"
  end
end
