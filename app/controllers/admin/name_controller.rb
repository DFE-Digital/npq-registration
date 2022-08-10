module Admin
  class NameController < AdminController
    def edit
      @user = Application.eager_load(:user).find(params[:application_id]).user
    end

    def update
      @user = Application.eager_load(:user).find(params[:application_id]).user

      @user.assign_attributes(name_params)
      changed = @user.changed?

      if @user.save
        flash[:success] = "Name updated" if changed

        redirect_to(admin_application_path(@user))
      else
        render :edit
      end
    end

  private

    def name_params
      params.require(:user).permit(:full_name)
    end
  end
end
