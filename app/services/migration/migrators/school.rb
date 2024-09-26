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
      migrate(self.class.ecf_schools) do |ecf_schools|
        ecf_schools.each do |ecf_school|
          find_school_id!(urn: ecf_school.urn, name: ecf_school.name.downcase)

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_school, e)
        end
      end
    end

  private

    def find_school_id!(urn:, name:)
      school_ids_by_urn_and_name.dig(urn, name) || raise(ActiveRecord::RecordNotFound, "Couldn't find School")
    end

    def school_ids_by_urn_and_name
      @school_ids_by_urn_and_name ||= begin
        schools = ::School.pluck(:id, :urn, :name)
        schools.each_with_object({}) do |(id, urn, name), hash|
          hash[urn] ||= {}
          hash[urn][name.downcase] = id
        end
      end
    end
  end
end
