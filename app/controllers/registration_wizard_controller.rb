class RegistrationWizardController < PublicPagesController
  before_action :registration_closed
  before_action :set_wizard
  before_action :set_form
  before_action :check_end_of_journey, only: %i[update]
  before_action :check_course_defined, only: %i[show]
  before_action :check_teacher_auth_user

  rescue_from FundingEligibility::MissingMandatoryInstitution, with: :redirect_to_institution_picker
  rescue_from RegistrationWizard::RemovedStep, with: :redirect_to_course_start_date

  FORMS_FOR_STEPS_BEFORE_COURSE_IS_CHOSEN = [
    Questionnaires::Start,
    Questionnaires::CourseStartDate,
    Questionnaires::CheckFunding,
    Questionnaires::TeacherCatchment,
    Questionnaires::ChooseYourNpq,
    Questionnaires::FundingYourNpq,
    Questionnaires::IneligibleForFunding,
    Questionnaires::Closed,
  ].freeze

  def show
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    @wizard.before_render

    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?
    return redirect_to root_path unless @form.requirements_met?

    render @wizard.current_step

    @wizard.after_render
  rescue ActionView::Template::Error => e
    if e.cause.instance_of?(Questionnaires::IneligibleForFunding::UnexpectedEligibilityStatusCode)
      redirect_to_course_start_date
    else
      raise e
    end
  end

  def update
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?
    return redirect_to root_path unless @form.requirements_met?

    if @form.valid?
      @wizard.save!

      if @form.redirect_to_change_path?
        redirect_to registration_wizard_show_change_path(@wizard.next_step_path)
      else
        redirect_to registration_wizard_show_path(@wizard.next_step_path)
      end
    else
      render @wizard.current_step
    end
  end

  def development_login
    return unless Rails.env.development?

    user_email = ENV["DEV_USER_EMAIL_FOR_LOGIN"]
    user = User.find_by!(email: user_email)
    session["user_id"] = user.id
    sign_in user
    wizard = RegistrationWizard.new(
      current_step: :login_callback,
      store: session["registration_store"],
      params: {},
      request:,
      current_user: user,
    )

    redirect_to registration_wizard_show_path(wizard.next_step_path)
  end

private

  def redirect_to_course_start_date
    redirect_to registration_wizard_show_path("course-start-date")
  end

  def redirect_to_institution_picker
    query_store = RegistrationQueryStore.new(store:)

    if query_store.works_in_school?
      flash[:error] = "Your application requires details of your school."
      redirect_to registration_wizard_show_path("choose-school")
    elsif query_store.kind_of_nursery_private?
      flash[:error] = "Your application requires details of your nursery."
      redirect_to registration_wizard_show_path("have-ofsted-urn")
    elsif query_store.works_in_childcare?
      flash[:error] = "Your application requires details of your early years setting."
      redirect_to registration_wizard_show_path("choose-childcare-provider")
    else
      raise "Could not resolve institution picker"
    end
  end

  def set_wizard
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore, store:, params: wizard_params, request:, current_user:)
  end

  def set_form
    @form = @wizard.form
  end

  def check_end_of_journey
    if @form.valid? && @form.last_step?
      @wizard.save!
      @wizard.store.clear
      redirect_to registration_complete_accounts_user_registration_path(current_user.applications.last)
    end
  end

  def check_course_defined
    return if FORMS_FOR_STEPS_BEFORE_COURSE_IS_CHOSEN.include?(@form.class)
    return if @wizard.query_store.course

    # redirect to course start date if the user has started the registration journey
    return redirect_to_course_start_date if @wizard.query_store.has_answers?

    # redirect to the start of the registration journey if the user has not started the registration journey
    redirect_to root_path
  end

  def registration_closed
    return if request.path == registration_wizard_show_path(:closed)

    if Feature.registration_closed?(current_user)
      if params[:step] == "start"
        redirect_to registration_closed_path(one_login: params[:one_login])
      else
        redirect_to registration_wizard_show_path(:closed)
      end
    end
  end

  def store
    session["registration_store"] ||= {}
  end

  def wizard_params
    return {} if Feature.registration_closed?(current_user)

    params.fetch(:registration_wizard, {}).permit(RegistrationWizard.permitted_params_for_step(params[:step].underscore))
  end

  def check_teacher_auth_user
    return unless @form.step_requires_login?
    return if current_user&.teacher_auth_provider?

    Sentry.capture_message("User attempted registration from GAI") if current_user&.get_an_identity_provider? # TODO: test

    redirect_to registration_wizard_show_path("continue-to-login")
  end
end
