module Migration::Ecf
  class NpqCourse < BaseRecord
    has_many :npq_applications

    def rebranded_alternative_courses
      case identifier
      when "npq-additional-support-offer"
        [self, NpqCourse.find_by(identifier: "npq-early-headship-coaching-offer")]
      when "npq-early-headship-coaching-offer"
        [self, NpqCourse.find_by(identifier: "npq-additional-support-offer")]
      else
        [self]
      end
    end
  end
end
