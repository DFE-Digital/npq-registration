class ImportGiasSchoolsJob < ApplicationJob
  queue_as :default

  def perform
    ImportGiasSchools.new.call
  end
end
