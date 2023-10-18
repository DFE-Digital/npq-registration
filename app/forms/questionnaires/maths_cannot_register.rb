module Questionnaires
  class MathsCannotRegister < Base
    def previous_step
      :maths_understanding_of_approach
    end

    def next_step; end
  end
end
