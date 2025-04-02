RSpec::Matchers.define :use_template do |expected_template|
  match do |mail|
    mail.template_id == expected_template
  end
end

RSpec::Matchers.define :have_personalisation do |expected_personalisation|
  match do |mail|
    mail.personalisation == expected_personalisation
  end
end
