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
        find_school!(urn: ecf_school.urn, name: ecf_school.name)
      end
    end

  private

    def find_school!(urn:, name:)
      schools_by_urn_and_name.dig(urn, name) || raise(ActiveRecord::RecordNotFound, "Couldn't find School")
    end

    def schools_by_urn_and_name
      @schools_by_urn_and_name ||= ::School.select(:urn, :name).all.each_with_object({}) do |school, hash|
        hash[school.urn] ||= {}
        hash[school.urn][school.name] = school
      end
    end
  end
end
