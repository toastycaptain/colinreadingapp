class Publisher::BaseController < ApplicationController
  include PublisherPortalAuthorization

  layout "publisher"

  before_action :authenticate_publisher_user!
  before_action :ensure_publisher_portal_enabled!

  helper_method :current_publisher

  private

  def current_publisher
    current_publisher_user.publisher
  end

  def ensure_publisher_portal_enabled!
    enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ENABLE_PUBLISHER_PORTAL", "true"))
    return if enabled

    head :not_found
  end

  def parsed_date(value, default)
    return default if value.blank?

    Date.parse(value)
  rescue ArgumentError
    default
  end
end
