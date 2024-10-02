# frozen_string_literal: true

module Dqt
  class TeacherRecord
    include ActiveModel::Model

    attr_accessor :trn,
                  :state_name,
                  :name,
                  :dob,
                  :ni_number,
                  :active_alert

    def active?
      state_name == "Active"
    end
  end
end
