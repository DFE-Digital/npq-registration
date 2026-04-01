module Registration
  class StepsController < PublicPagesController
    include RegistrationWizardState
    before_action :set_wizard, :registration_closed, :validate_step_access

    def show
      @form = @wizard.current_step
    end

    def update
      if @wizard.save_current_step
        redirect_to @wizard.next_step_path
      else
        @form = @wizard.current_step
        render :show
      end
    end

  private

    def set_wizard
      @wizard = Registration::Wizard.new(
        current_step: (params[:step] || :name).to_s.underscore.to_sym,
        current_step_params: params,
        state_store:,
      )
    end

    def validate_step_access
      return if @wizard.valid_path_to_current_step?

      last_valid_step = @wizard.valid_path(:check_answers).last
      last_valid_step ||= @wizard.valid_path(:start).last
      return redirect_to root_path unless last_valid_step

      next_step = @wizard.steps_processor.next_step(last_valid_step)
      redirect_to @wizard.resolve_step_path(next_step || last_valid_step)
    end

    def registration_closed
      if @wizard.current_step_name == @wizard.root_step &&
          Feature.registration_closed?(current_user)
        redirect_to registration_closed_path
      end
    end
  end
end
