class ApplicationController < ActionController::Base
  include ErrorRenderable

  protect_from_forgery with: :exception
  skip_forgery_protection if: -> { request.format.json? }

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  private

  def render_not_found(exception)
    render_error(code: "not_found", message: exception.message, status: :not_found)
  end

  def render_record_invalid(exception)
    render_error(
      code: "validation_failed",
      message: "Validation failed",
      status: :unprocessable_entity,
      details: exception.record.errors.to_hash,
    )
  end

  def render_parameter_missing(exception)
    render_error(
      code: "bad_request",
      message: exception.message,
      status: :bad_request,
    )
  end
end
