class ProfilesController < ApplicationController
  def show
    @user = current_user
    @profile_inputs = {}
  end

  def update
    @user = current_user
    @profile_inputs = params.expect(profile: [ :display_name, :birth_date, *User::PROFILE_MEASURES ]).to_h

    # SQL debug logs can include inline values when prepared statements are disabled.
    saved = User.logger.silence(Logger::INFO) { @user.update(profile_attributes) }
    if saved
      redirect_to profile_path, notice: "Perfil atualizado.", status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_attributes
    attributes = @profile_inputs.dup
    User::PROFILE_MEASURES.each do |field|
      value = attributes[field]
      attributes[field] = value.strip.tr(",", ".") if value.is_a?(String)
    end
    attributes
  end
end
