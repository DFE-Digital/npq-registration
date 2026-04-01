module Registration
  class Wizard
    include DfE::Wizard

    class BlankStep < RuntimeError; end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :start, Questionnaires::Start
        graph.add_node :closed, Questionnaires::Closed
        graph.add_node :teacher_reference_number, Questionnaires::TeacherReferenceNumber
        graph.add_node :dont_have_teacher_reference_number, Questionnaires::DontHaveTeacherReferenceNumber
        graph.add_node :qualified_teacher_check, Questionnaires::QualifiedTeacherCheck
        graph.add_node :dqt_mismatch, Questionnaires::DqtMismatch
        graph.add_node :course_start_date, Questionnaires::CourseStartDate
        graph.add_node :provider_check, Questionnaires::ProviderCheck
        graph.add_node :cannot_register_yet, Questionnaires::CannotRegisterYet
        graph.add_node :teacher_catchment, Questionnaires::TeacherCatchment
        graph.add_node :choose_an_npq_and_provider, Questionnaires::ChooseAnNpqAndProvider
        graph.add_node :work_setting, Questionnaires::WorkSetting
        graph.add_node :choose_school, Questionnaires::ChooseSchool
        graph.add_node :school_not_in_england, Questionnaires::SchoolNotInEngland
        graph.add_node :kind_of_nursery, Questionnaires::KindOfNursery
        graph.add_node :referred_by_return_to_teaching_adviser,
                       Questionnaires::ReferredByReturnToTeachingAdviser
        graph.add_node :your_employment, Questionnaires::YourEmployment
        graph.add_node :itt_provider, Questionnaires::IttProvider
        graph.add_node :your_role, Questionnaires::YourRole
        graph.add_node :your_employer, Questionnaires::YourEmployer
        graph.add_node :have_ofsted_urn, Questionnaires::HaveOfstedUrn
        graph.add_node :choose_private_childcare_provider,
                       Questionnaires::ChoosePrivateChildcareProvider
        graph.add_node :choose_childcare_provider, Questionnaires::ChooseChildcareProvider
        graph.add_node :childcare_provider_not_in_england,
                       Questionnaires::ChildcareProviderNotInEngland
        graph.add_node :choose_your_npq, Questionnaires::ChooseYourNpq
        graph.add_node :npqh_status, Questionnaires::NpqhStatus
        graph.add_node :choose_your_provider, Questionnaires::ChooseYourProvider
        graph.add_node :ineligible_for_funding, Questionnaires::IneligibleForFunding
        graph.add_node :maths_eligibility_teaching_for_mastery,
                       Questionnaires::MathsEligibilityTeachingForMastery
        graph.add_node :senco_in_role, Questionnaires::SencoInRole
        graph.add_node :possible_funding, Questionnaires::PossibleFunding
        graph.add_node :ehco_headteacher, Questionnaires::EhcoHeadteacher
        graph.add_node :ehco_unavailable, Questionnaires::EhcoUnavailable
        graph.add_node :ehco_new_headteacher, Questionnaires::EhcoNewHeadteacher
        graph.add_node :ehco_funding_not_available, Questionnaires::EhcoFundingNotAvailable
        graph.add_node :funding_your_ehco, Questionnaires::FundingYourEhco
        graph.add_node :ehco_possible_funding, Questionnaires::EhcoPossibleFunding
        graph.add_node :ehco_previously_funded, Questionnaires::EhcoPreviouslyFunded
        graph.add_node :share_provider, Questionnaires::ShareProvider
        graph.add_node :funding_your_npq, Questionnaires::FundingYourNpq
        graph.add_node :maths_understanding_of_approach,
                       Questionnaires::MathsUnderstandingOfApproach
        graph.add_node :funding_eligibility_maths, Questionnaires::FundingEligibilityMaths
        graph.add_node :maths_cannot_register, Questionnaires::MathsCannotRegister
        graph.add_node :senco_start_date, Questionnaires::SencoStartDate
        graph.add_node :funding_eligibility_senco, Questionnaires::FundingEligibilitySenco

        graph.add_node :check_answers, Questionnaires::CheckAnswers
        graph.add_node :applications_list, DfE::Wizard::Redirect

        graph.root :start

        graph.add_multiple_conditional_edges(
          from: :start,
          branches: [
            { when: :service_closed?, then: :closed },
            { when: :user_missing_trn?, then: :teacher_reference_number },
          ],
          default: :course_start_date,
        )

        graph.add_conditional_edge(
          from: :teacher_reference_number,
          when: :user_does_not_know_trn?,
          then: :dont_have_teacher_reference_number,
          else: :qualified_teacher_check,
        )

        graph.add_conditional_edge(
          from: :qualified_teacher_check,
          when: :trn_is_verified?,
          then: :course_start_date,
          else: :dqt_mismatch,
        )

        graph.add_edge from: :dqt_mismatch, to: :course_start_date

        graph.add_conditional_edge(
          from: :course_start_date,
          when: :not_starting_in_current_cohort?,
          then: :cannot_register_yet,
          else: :provider_check,
        )

        graph.add_conditional_edge(
          from: :provider_check,
          when: :not_chosen_provider?,
          then: :choose_an_npq_and_provider,
          else: :teacher_catchment,
        )

        graph.add_edge from: :teacher_catchment, to: :work_setting

        graph.add_multiple_conditional_edges(
          from: :work_setting,
          branches: [
            { when: :inside_catchment_and_works_in_school?, then: :choose_school },
            { when: :inside_catchment_and_works_in_childcare?, then: :kind_of_nursery },
            { when: :inside_catchment_and_works_in_other?, then: :referred_by_return_to_teaching_adviser },
            { when: :inside_catchment?, then: :your_employment },
          ],
          default: :choose_your_npq,
        )

        graph.add_conditional_edge(
          from: :choose_school,
          when: :institution_not_in_england?,
          then: :school_not_in_england,
          else: :choose_your_npq,
        )

        graph.add_conditional_edge(
          from: :kind_of_nursery,
          when: :kind_of_nursery_private?,
          then: :have_ofsted_urn,
          else: :choose_childcare_provider,
        )

        graph.add_multiple_conditional_edges(
          from: :your_employment,
          branches: [
            { when: :lead_mentor_for_accredited_itt_provider?, then: :itt_provider },
            { when: :employment_type_hospital_school?, then: :your_employer },
            { when: :young_offender_institution?, then: :your_employer },
          ],
          default: :your_role,
        )

        graph.add_edge from: :referred_by_return_to_teaching_adviser, to: :choose_your_npq
        graph.add_edge from: :itt_provider, to: :choose_your_npq
        graph.add_edge from: :your_role, to: :your_employer
        graph.add_edge from: :your_employer, to: :choose_your_npq

        graph.add_conditional_edge(
          from: :have_ofsted_urn,
          when: :has_ofsted_urn?,
          then: :choose_private_childcare_provider,
          else: :choose_your_npq,
        )

        graph.add_edge from: :choose_private_childcare_provider, to: :choose_your_npq

        graph.add_conditional_edge(
          from: :choose_childcare_provider,
          when: :institution_not_in_england?,
          then: :childcare_provider_not_in_england,
          else: :choose_your_npq,
        )

        graph.add_multiple_conditional_edges(
          from: :choose_your_npq,
          branches: [
            { when: :ehco_course?, then: :npqh_status },
            { when: :leading_primary_maths_course?, then: :maths_eligibility_teaching_for_mastery },
            { when: :senco_course?, then: :senco_in_role },
            { when: :eligible_for_funding?, then: :possible_funding },
            { when: :funded_subject_to_review?, then: :possible_funding },
          ],
          default: :ineligible_for_funding,
        )

        graph.add_conditional_edge(
          from: :npqh_status,
          when: :headship_course_requirement?,
          then: :ehco_headteacher,
          else: :ehco_unavailable,
        )

        graph.add_conditional_edge(
          from: :ehco_headteacher,
          when: :ehco_headteacher?,
          then: :ehco_new_headteacher,
          else: :ehco_funding_not_available,
        )

        graph.add_multiple_conditional_edges(
          from: :ehco_new_headteacher,
          branches: [
            { when: :eligible_for_funding?, then: :ehco_possible_funding },
            { when: :funded_subject_to_review?, then: :possible_funding },
            { when: :previously_funded?, then: :ehco_previously_funded },
          ],
          default: :ehco_funding_not_available,
        )

        graph.add_edge from: :ehco_unavailable, to: :choose_your_npq
        graph.add_edge from: :ehco_funding_not_available, to: :funding_your_ehco
        graph.add_edge from: :ehco_possible_funding, to: :choose_your_provider
        graph.add_edge from: :ehco_previously_funded, to: :funding_your_ehco
        graph.add_edge from: :funding_your_ehco, to: :choose_your_provider
        graph.add_edge from: :choose_your_provider, to: :share_provider
        graph.add_edge from: :share_provider, to: :check_answers
        graph.add_edge from: :ineligible_for_funding, to: :funding_your_npq
        graph.add_edge from: :funding_your_npq, to: :choose_your_provider
        graph.add_edge from: :possible_funding, to: :choose_your_provider
        graph.add_edge from: :check_answers, to: :applications_list

        graph.add_multiple_conditional_edges(
          from: :maths_eligibility_teaching_for_mastery,
          branches: [
            { when: :ineligible_for_maths_mastery?, then: :maths_understanding_of_approach },
            { when: :eligible_for_funding?, then: :funding_eligibility_maths },
            { when: :funded_subject_to_review?, then: :possible_funding },
          ],
          default: :ineligible_for_funding,
        )

        graph.add_multiple_conditional_edges(
          from: :maths_understanding_of_approach,
          branches: [
            { when: :maths_cannot_show_understanding_of_approach?, then: :maths_cannot_register },
            { when: :eligible_for_funding?, then: :funding_eligibility_maths },
            { when: :funded_subject_to_review?, then: :possible_funding },
          ],
          default: :ineligible_for_funding,
        )

        graph.add_edge from: :funding_eligibility_maths, to: :choose_your_provider

        graph.add_multiple_conditional_edges(
          from: :senco_in_role,
          branches: [
            { when: :senco_in_role?, then: :senco_start_date },
            { when: :eligible_for_funding?, then: :funding_eligibility_senco },
            { when: :funded_subject_to_review?, then: :possible_funding },
          ],
          default: :ineligible_for_funding,
        )

        graph.add_multiple_conditional_edges(
          from: :senco_start_date,
          branches: [
            { when: :eligible_for_funding?, then: :funding_eligibility_senco },
            { when: :funded_subject_to_review?, then: :possible_funding },
          ],
          default: :ineligible_for_funding,
        )

        graph.add_edge from: :funding_eligibility_senco, to: :choose_your_provider

        graph.before_next_step(:onward_to_check_answers)
        graph.before_previous_step(:back_to_check_answers)
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self) do |b|
        b.on_step(:qualified_teacher_check, add: [CheckUserAgainstDqt])
        b.on_step(:check_answers, add: [CreateApplication, ClearApplicationData])
      end
    end

    def extract_step_params_from_request
      if @current_step_params.is_a?(ActionController::Parameters)
        @current_step_params.require(:registration_wizard).permit(permitted_params)
      else
        @current_step_params.fetch(:registration_wizard, {})
      end
    end

    def valid_answers_store
      ValidPathAnswers.state_store(self)
    end

    def check_answers_presenter
      @check_answers_presenter ||= CheckAnswersPresenter.new(valid_answers_store)
    end
    delegate :answers, to: :check_answers_presenter

    def query_store = state_store
    def store = state_store

    def onward_to_check_answers
      return if current_step_params[:return_to_review].blank?
      return unless valid_path_to?(:check_answers)

      :check_answers
    end

    def back_to_check_answers
      return unless current_step_params[:return_to_review].to_s == current_step_name.to_s
      return unless valid_path_to?(:check_answers)

      :check_answers
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: lambda { |step, state_store, urls, params|
          if step.blank?
            raise BlankStep
          elsif step&.to_sym == :applications_list
            urls.accounts_user_registration_path(state_store.current_user.applications.last, success: true)
          else
            urls.registration_wizard_show_path(step && step.to_s.dasherize, params)
          end
        },
      )
    end

    def logger
      DfE::Wizard::Logging::Logger.new(Rails.logger) if Rails.env.development?
    end

    def inspect(...)
      return super unless Rails.env.development?

      DfE::Wizard::Tooling::Inspect.new(wizard: self)
    end
  end
end
