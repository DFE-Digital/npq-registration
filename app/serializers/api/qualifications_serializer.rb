module API
  class QualificationsSerializer < Blueprinter::Base
    field :trn do |object, _options|
      object
    end

    class AttributesSerializer < Blueprinter::Base
      field :completion_date, name: :award_date, datetime_format: "%Y-%m-%d"
      field :course_short_code, name: :npq_type
    end

    association :qualifications, blueprint: AttributesSerializer do |_object, options|
      options[:participant_outcomes]
    end
  end
end
