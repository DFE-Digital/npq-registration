module Forms
  class ContactDetails < Base
    attr_accessor :email

    validates :email, presence: true, email: true

    def self.permitted_params
      %i[
        email
      ]
    end

    def next_step
      :confirm_email
    end

    def previous_step
      if wizard.store["changed_name"] == "no"
        :name_changes
      elsif wizard.store["updated_name"] == "yes"
        :updated_name
      elsif wizard.store["name_not_updated_action"] == "use_old_name"
        :not_updated_name
      else # fail safe
        :start
      end
    end

    def after_save
      wizard.store["generated_confirmation_code"] = code
      ConfirmEmailMailer.confirmation_code_mail(to: email, code: code).deliver_now
    end

    def code
      @code ||= Services::OtpCodeGenerator.new.call
    end
  end
end
