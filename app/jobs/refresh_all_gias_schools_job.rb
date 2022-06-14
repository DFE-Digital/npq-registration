class RefreshAllGiasSchoolsJob < ApplicationJob
  queue_as :default

  def perform
    Services::ImportGiasSchools.new(refresh_all: true).call
  end
end
