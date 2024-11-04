module Migration::Migrators
  class School < Base
    class << self
      def record_count
        ecf_schools.count
      end

      def model
        :school
      end

      def ecf_schools
        Migration::Ecf::School
          .includes(:npq_applications)
          .where.not(npq_applications: { id: nil })
      end
    end

    def call
      migrate(self.class.ecf_schools) do |ecf_school|
        find_school_id!(urn: ecf_school.urn)
      end
    end
  end
end
