def seed_courses!
  [
    {
      position: 0,
      name: "Additional Support Offer for new headteachers",
      ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
      identifier: "npq-additional-support-offer",
      description: "The Additional Support Offer is a targeted support package for new headteachers.",
      display: false,
    },
    {
      position: 1,
      name: "NPQ for Leading Teaching (NPQLT)",
      ecf_id: "15c52ed8-06b5-426e-81a2-c2664978a0dc",
      identifier: "npq-leading-teaching",
      display: true,
    },
    {
      position: 2,
      name: "NPQ for Leading Behaviour and Culture (NPQLBC)",
      ecf_id: "7d47a0a6-fa74-4587-92cc-cd1e4548a2e5",
      identifier: "npq-leading-behaviour-culture",
      display: true,
    },
    {
      position: 3,
      name: "NPQ for Leading Teacher Development (NPQLTD)",
      ecf_id: "29fee78b-30ce-4b93-ba21-80be2fde286f",
      identifier: "npq-leading-teaching-development",
      display: true,
    },
    {
      position: 4,
      name: "NPQ for Leading Literacy (NPQLL)",
      ecf_id: "829fcd45-e39d-49a9-b309-26d26debfa90",
      identifier: "npq-leading-literacy",
      display: true,
    },
    {
      position: 5,
      name: "NPQ for Senior Leadership (NPQSL)",
      ecf_id: "a42736ad-3d0b-401d-aebe-354ef4c193ec",
      identifier: "npq-senior-leadership",
      display: true,
    },
    {
      position: 6,
      name: "NPQ for Headship (NPQH)",
      ecf_id: "0f7d6578-a12c-4498-92a0-2ee0f18e0768",
      identifier: "npq-headship",
      display: true,
    },
    {
      position: 7,
      name: "NPQ for Executive Leadership (NPQEL)",
      ecf_id: "aef853f2-9b48-4b6a-9d2a-91b295f5ca9a",
      identifier: "npq-executive-leadership",
      display: true,
    },
    {
      position: 8,
      name: "NPQ for Early Years Leadership (NPQEYL)",
      ecf_id: "66dff4af-a518-498f-9042-36a41f9e8aa7",
      identifier: "npq-early-years-leadership",
      display: true,
    },
    {
      position: 9,
      name: "Early Headship Coaching Offer",
      ecf_id: "0222d1a8-a8e1-42e3-a040-2c585f6c194a",
      identifier: "npq-early-headship-coaching-offer",
      description: "The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.",
      display: true,
    },
  ].each do |hash|
    course = Course.find_or_initialize_by(ecf_id: hash[:ecf_id])
    course.update!(
      name: hash[:name],
      description: hash[:description],
      position: hash[:position],
      display: hash[:display],
      identifier: hash[:identifier],
    )

    next if hash[:default_cohort].nil?

    course.update!(
      default_cohort: hash[:default_cohort],
    )
  end
end

def seed_lead_providers!
  Services::LeadProviders::Updater.call
end

# IDs have been hard coded to be the same across all envs
seed_courses!
seed_lead_providers!
