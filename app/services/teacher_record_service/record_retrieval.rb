module TeacherRecordService
  class RecordRetrieval
    MAX_RETRIES = 1

    Result = Struct.new(:teaching_record, :full_name, :previous_names, :success?, :error_type)

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      teaching_record = fetch_teaching_record_with_retry

      if teaching_record
        Result.new(
          teaching_record,
          build_full_name(teaching_record),
          format_previous_names(teaching_record),
          true,
          nil,
        )
      else
        Result.new(nil, nil, [], false, :api_error)
      end
    rescue Timeout::Error
      Result.new(nil, nil, [], false, :timeout)
    rescue StandardError
      Result.new(nil, nil, [], false, :unknown_error)
    end

  private

    attr_reader :access_token

    def fetch_teaching_record_with_retry
      @trs_retries ||= 0

      V3::Person.find_with_token(access_token:)
    rescue Timeout::Error => e
      raise e if (@trs_retries += 1) > MAX_RETRIES

      retry
    end

    def build_full_name(record)
      return nil unless record

      [
        record["firstName"],
        record["middleName"],
        record["lastName"],
      ].compact.join(" ")
    end

    def format_previous_names(record)
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
