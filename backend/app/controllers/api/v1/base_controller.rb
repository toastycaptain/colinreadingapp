class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def require_parent!
    return if current_user&.parent?

    render_error(code: "forbidden", message: "Parent role required", status: :forbidden)
  end
end
