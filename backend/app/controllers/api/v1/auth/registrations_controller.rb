class Api::V1::Auth::RegistrationsController < ApplicationController
  def create
    user = User.new(registration_params.merge(role: :parent))
    user.save!

    render json: {
      user: serialize_user(user),
      jwt: JwtTokenIssuer.call(user),
    }, status: :created
  end

  private

  def registration_params
    params.permit(:email, :password)
  end

  def serialize_user(user)
    user.as_json(only: %i[id email role created_at updated_at])
  end
end
