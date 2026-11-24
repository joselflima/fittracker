class SessionsController < ApplicationController
  skip_before_action :require_login, except: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Aguarde alguns minutos para tentar novamente." }

  def new
    redirect_to root_path if current_user
  end

  def create
    if (user = User.authenticate_by(email: params[:email], password: params[:password]))
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, status: :see_other
    else
      flash.now[:alert] = "Confira seu e-mail e sua senha."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, status: :see_other
  end
end
