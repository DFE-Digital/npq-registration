module Registration
  class Wizard
    include DfE::Wizard

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :start, Questionnaires::Start
        graph.add_node :course_start_date, Questionnaires::CourseStartDate
        graph.add_node :cannot_register_yet, Questionnaires::CannotRegisterYet
        graph.add_node :check_answers, Questionnaires::CheckAnswers
        graph.add_node :applications_list, DfE::Wizard::Redirect

        graph.root :start

        graph.add_edge from: :start, to: :course_start_date

        graph.add_conditional_edge(
          from: :course_start_date,
          when: :not_starting_in_current_cohort?,
          then: :cannot_register_yet,
          else: :check_answers,
        )

        graph.add_edge from: :check_answers, to: :applications_list

        graph.before_next_step(:onward_to_check_answers)
        graph.before_previous_step(:back_to_check_answers)
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self) do |b|
        b.on_step(:check_answers, add: [ClearApplicationData])
      end
    end

    def extract_step_params_from_request
      if @current_step_params.is_a?(ActionController::Parameters)
        @current_step_params.require(:registration_wizard).permit(permitted_params)
      else
        @current_step_params.fetch(:registration_wizard, {})
      end
    end

    def check_answers_presenter
      @check_answers_presenter ||= CheckAnswersPresenter.new(state_store)
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
