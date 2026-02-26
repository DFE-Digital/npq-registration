module TeachingRecordSystem
  class FetchPerson
    attr_reader :teaching_record, :full_name, :previous_names

    def self.fetch(access_token:)
      person_data = V3::Person.find_with_token(access_token:)
      new(person_data)
    end

  private

    def initialize(person_data)
      @teaching_record = person_data
      @full_name = parse_full_name(person_data)
      @previous_names = parse_previous_names(person_data)
    end

    def parse_full_name(record)
      [
        record["firstName"],
        record["middleName"],
        record["lastName"],
      ].compact.join(" ")
    end

    def parse_previous_names(record)
      return [] unless record&.dig("previousNames")

      record["previousNames"].map do |name|
        [
          name["firstName"],
          name["middleName"],
          name["lastName"],
        ].compact.join(" ")
      end
    end
  end
end
