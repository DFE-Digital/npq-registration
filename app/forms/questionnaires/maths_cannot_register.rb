module Questionnaires
  class MathsCannotRegister < Base
    def previous_step
      :maths_understanding_of_approach
    end

    def next_step
      # you cannot proceed any further from this step
    end
  end
end
