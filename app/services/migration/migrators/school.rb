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
        ::School.find_by!(urn: ecf_school.urn, name: ecf_school.name)
      end
    end
  end
end
