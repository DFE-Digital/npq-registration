module Forms
  class NpqhStatus < Base
    include Helpers::Institution

    attr_accessor :npqh_status

    validates :npqh_status, presence: true

    def self.permitted_params
      %i[
        npqh_status
      ]
    end

    def next_step
      if npqh_status == "none"
        :aso_unavailable
      else
        :aso_headteacher
      end
    end

    def previous_step
      :about_aso
    end

    def options
      options_array.each_with_index.map do |option, index|
        OpenStruct.new(value: option[:value],
                       text: option[:text],
                       link_errors: index.zero?)
      end
    end

  private

    def options_array
      [
        {
          text: "I have completed an NPQH",
          value: "completed_npqh",
        },
        {
          text: "I am still studying for an NPQH",
          value: "studying_npqh",
        },
        {
          text: "I am about to start an NPQH",
          value: "will_start_npqh",
        },
        {
          text: "None of the above",
          value: "none",
        },
      ]
    end
  end
end
