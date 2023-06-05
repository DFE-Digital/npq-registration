module Forms::FlowHelper
  def first_questionnaire_step
    if Services::Feature.trn_required? && query_store.current_user.trn.blank?
      :teacher_reference_number
    else
      :provider_check
    end
  end
end
