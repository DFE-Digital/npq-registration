import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "answerRadioYes",
    "answerRadioNoDontHave",
    "questionForm"
  ]

  connect() {
    this.onAnswerChange();
  }

  onAnswerChange(event) {
    if (this.answerRadioYesTarget.checked) {
      this.questionFormTarget.setAttribute("data-remote", "true");
    } else {
      this.questionFormTarget.setAttribute("data-remote", "false");
    }
  }
}
