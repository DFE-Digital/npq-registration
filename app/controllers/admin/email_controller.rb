module Admin
  class EmailController < AdminController
    def edit
      @user = Application.eager_load(:user).find(params[:application_id]).user
    end

    def update
      @user = Application.eager_load(:user).find(params[:application_id]).user

      @user.assign_attributes(email_params)
      changed = @user.changed?

      if @user.save
        flash[:success] = "Email address updated" if changed

        redirect_to(admin_application_path(@user))
      else
        render :edit
      end
    end

  private

    def email_params
      params.require(:user).permit(:email)
    end
  end
end
