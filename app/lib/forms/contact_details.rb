module Forms
  class ContactDetails < Base
    TEST_DOMAINS = %w[
      example.com
      ambition.org.uk
      churchofengland.org
      pracedo.com
      ucl.ac.uk
      tribalgroup.com
      teachfirst.org.uk
      educationdevelopmenttrust.com
      capita.com
      bestpracticenet.co.uk
      aircury.com
      setsquaresolutions.com
      harrisfederation.org.uk
      harrischaffordhundred.org.uk
      llse.org.uk
      realgroup.co.uk
      teacherdevelopmenttrust.org 
      uclconsultants.com
    ].freeze

    attr_reader :email

    validates :email, presence: true, email: true, length: { maximum: 128 }

    def self.permitted_params
      %i[
        email
      ]
    end

    def email=(value)
      unless value.nil?
        @email = value.strip.downcase
      end
    end

    def next_step
      if changing_answer? && !email_confirmed?
        :confirm_email
      elsif changing_answer? && no_answers_will_change?
        :check_answers
      elsif email_confirmed?
        :qualified_teacher_check
      else
        :confirm_email
      end
    end

    def previous_step
      :teacher_reference_number
    end

    def after_save
      wizard.store["generated_confirmation_code"] = code
      ConfirmEmailMailer.confirmation_code_mail(to: email, code: code).deliver_now
      set_flash_message
    end

  private

    def set_flash_message
      wizard.request.flash[:success] = if sandbox? && whitelisted_domain?
                                         "Your code is #{code}"
                                       else
                                         "We’ve emailed a confirmation code to #{email}"
                                       end
    end

    def sandbox?
      ENV["SERVICE_ENV"] == "sandbox"
    end

    def whitelisted_domain?
      TEST_DOMAINS.any? { |domain| email.include?(domain) }
    end

    def code
      @code ||= Services::OtpCodeGenerator.new.call
    end

    def email_confirmed?
      email == wizard.store["confirmed_email"]
    end
  end
end
