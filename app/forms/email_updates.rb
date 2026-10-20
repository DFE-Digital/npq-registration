class EmailUpdates
  include ActiveModel::Model

  attr_accessor :email, :course

  validates :email, presence: true, email: true
  validates :course, presence: true, inclusion: { in: RegistrationInterest.courses.values }

  def questions
    [
      QuestionTypes::TextField.new(
        name: :email,
        style_options: { width: "one-half", label: { size: "m", tag: "h2" } },
      ),
      QuestionTypes::RadioButtonGroup.new(
        name: :course,
        options:,
        style_options: { legend: { size: "m", tag: "h2" } },
      ),
    ]
  end

  def options
    [
      build_option_struct(value: "npq-senco", label: "Yes", link_errors: true),
      build_option_struct(value: "other", label: "No, I want to do a different NPQ"),
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
