class Api::V1::Auth::SessionsController < ApplicationController
  before_action :authenticate_user!, only: :destroy

  def create
    user = User.find_for_database_authentication(email: params[:email])

    unless user&.valid_password?(params[:password])
      return render_error(code: "invalid_credentials", message: "Invalid email or password", status: :unauthorized)
    end

    render json: {
      user: user.as_json(only: %i[id email role created_at updated_at]),
      jwt: JwtTokenIssuer.call(user),
    }
  end

  def destroy
    current_user.update!(jti: SecureRandom.uuid)
    head :no_content
  end
end
