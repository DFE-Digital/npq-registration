module API
  module V3
    class ParticipantsController < BaseController
      def index
        Participants::IndexService.find_all

        render 'api/v3/participants/index', status: :ok
      end

      def show
        Participants::ShowService.find

        render 'api/v3/participants/show', status: :ok
      end

      def change_schedule
        Participants::ChangeSchedule.change(@participant)
      end

      def resume
        Participants::ResumeService.resume(@participant)

        render 'api/v3/participants/resume', status: :ok
      end

      def withdraw
        Participants::WithdrawService.withdraw(@participant)

        render 'api/v3/participants/withdraw', status: :ok
      end

      def resume
        Participants::ResumeService.resume(@participant)

        render 'api/v3/participants/resume', status: :ok
      end

      def outcomes = head(:method_not_allowed)
    end
  end
end
