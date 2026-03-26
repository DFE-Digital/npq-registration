module Questionnaires::FlowHelper
  def first_questionnaire_step
    if !query_store.current_user.teacher_auth_provider? && Feature.trn_required? && query_store.current_user.trn.blank?
      :teacher_reference_number
    else
      :course_start_date
    end
  end
end
