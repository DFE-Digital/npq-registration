module Migration::Migrators
  class School < Base
    def call
      migrate(ecf_schools, :school) do |ecf_school|
        ::School.find_by!(urn: ecf_school.urn, name: ecf_school.name)
      end
    end

  private

    def ecf_schools
      @ecf_schools ||= Migration::Ecf::School
        .includes(:npq_applications)
        .where.not(npq_applications: { id: nil })
    end
  end
end
