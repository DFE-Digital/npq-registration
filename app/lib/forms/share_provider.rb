module Forms
  class ShareProvider
    include ActiveModel::Model

    attr_accessor :can_share_choices

    validates :can_share_choices, acceptance: true
  end
end
