class ImportGiasSchoolsJob < ApplicationJob
  queue_as :default

  def perform
    Services::ImportGiasSchools.new.call
  end
end
