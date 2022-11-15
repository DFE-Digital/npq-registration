module Forms
  class GetAnIdentity < Base
    def next_step
      :get_an_identity
    end

    def previous_step
      :teacher_reference_number
    end
  end
end
