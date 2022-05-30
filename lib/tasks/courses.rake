namespace :courses do
  desc "Update courses"
  task update: :environment do
    Rake::Task["courses:update_names"].invoke
    Rake::Task["courses:update_positions"].invoke
  end

  desc "Update courses names"
  task update_names: :environment do
    Rails.logger.info("Updating courses names")
    ensure_courses_exist!

    courses.each do |hash|
      Course.find_by!(ecf_id: hash[:ecf_id]).update!(name: hash[:name])
    end

    Rails.logger.info("Courses names update finished")
  end

  desc "Update courses positions"
  task update_positions: :environment do
    Rails.logger.info("Updating courses positions")
    ensure_courses_exist!

    courses.each do |hash|
      Course.find_by!(ecf_id: hash[:ecf_id]).update!(position: hash[:position])
    end

    Rails.logger.info("Courses positions update finished")
  end
end

def courses
  [
    { ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7", position: 0, name: "Additional Support Offer for new headteachers" },
    { ecf_id: "15c52ed8-06b5-426e-81a2-c2664978a0dc", position: 1, name: "NPQ for Leading Teaching (NPQLT)" },
    { ecf_id: "7d47a0a6-fa74-4587-92cc-cd1e4548a2e5", position: 2, name: "NPQ for Leading Behaviour and Culture (NPQLBC)" },
    { ecf_id: "29fee78b-30ce-4b93-ba21-80be2fde286f", position: 3, name: "NPQ for Leading Teacher Development (NPQLTD)" },
    { ecf_id: "829fcd45-e39d-49a9-b309-26d26debfa90", position: 4, name: "NPQ for Leading Literacy (NPQLL)" },
    { ecf_id: "a42736ad-3d0b-401d-aebe-354ef4c193ec", position: 5, name: "NPQ for Senior Leadership (NPQSL)" },
    { ecf_id: "0f7d6578-a12c-4498-92a0-2ee0f18e0768", position: 6, name: "NPQ for Headship (NPQH)" },
    { ecf_id: "aef853f2-9b48-4b6a-9d2a-91b295f5ca9a", position: 7, name: "NPQ for Executive Leadership (NPQEL)" },
    { ecf_id: "66dff4af-a518-498f-9042-36a41f9e8aa7", position: 8, name: "NPQ for Early Years Leadership (NPQEYL)" },
    { ecf_id: "0222d1a8-a8e1-42e3-a040-2c585f6c194a", position: 9, name: "Early Headship Coaching Offer" },
  ]
end

def ensure_courses_exist!
  ecf_ids = courses.map { |c| c[:ecf_id] }
  all_courses_exist = Course.where(ecf_id: ecf_ids).count == ecf_ids.count

  error_msg = "Task aborted! Trying to update courses that do not exist."

  unless all_courses_exist
    Rails.logger.error(error_msg)
    abort(error_msg)
  end
end
