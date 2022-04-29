module Forms
  class ChoosePrivateChildcareProvider < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_identifier, format: { with: /\APrivateChildcareProvider-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :have_ofsted_urn
    end
  end
end
