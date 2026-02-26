class Api::V1::Auth::PasswordsController < ApplicationController
  def forgot
    email = params[:email].to_s.downcase
    user = User.find_by(email: email)

    if user
      token = user.send(:set_reset_password_token)
      reset_url = params[:reset_url].presence
      UserMailer.with(user: user, token: token, reset_url: reset_url).password_reset_requested.deliver_later
    end

    head :ok
  end

  def reset
    user = User.reset_password_by_token(reset_params)

    if user.errors.empty?
      render json: {
        user: user.as_json(only: %i[id email role created_at updated_at]),
      }
    else
      render_error(
        code: "password_reset_failed",
        message: "Unable to reset password",
        status: :unprocessable_entity,
        details: user.errors.to_hash,
      )
    end
  end

  private

  def reset_params
    params.permit(:reset_password_token, :password)
  end
end
