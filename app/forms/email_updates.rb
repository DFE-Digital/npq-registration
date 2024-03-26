class EmailUpdates
  include ActiveModel::Model

  attr_accessor :email_updates_status

  validates :email_updates_status, presence: true, inclusion: { in: User::EMAIL_UPDATES_STATES.map(&:to_s) }

  def questions
    [
      QuestionTypes::RadioButtonGroup.new(
        name: :email_updates_status,
        options:,
        style_options: { legend: { size: "xl", tag: "h1" } },
        ),
    ]
  end

  def options
    [
      build_option_struct(value: :senco, label: "Yes", link_errors: true),
      build_option_struct(value: :other_npq, label: "No, I want to do a different NPQ"),
    ]
  end

  def build_option_struct(value:, label: nil, hint: nil, link_errors: false, divider: false, revealed_question: nil)
    QuestionTypes::RadioOption.new(
      value:,
      label:,
      hint:,
      link_errors:,
      divider:,
      revealed_question:,
      )
  end
end
