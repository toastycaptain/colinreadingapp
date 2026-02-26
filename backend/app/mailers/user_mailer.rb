class UserMailer < ApplicationMailer
  def welcome_parent
    @user = params.fetch(:user)
    mail(to: @user.email, subject: "Welcome to Storytime")
  end

  def parental_consent_received
    @user = params.fetch(:user)
    @policy_version = params.fetch(:policy_version)
    mail(to: @user.email, subject: "Parental consent recorded")
  end

  def deletion_request_received
    @user = params.fetch(:user)
    @deletion_request = params.fetch(:deletion_request)
    mail(to: @user.email, subject: "Deletion request received")
  end

  def password_reset_requested
    @user = params.fetch(:user)
    @token = params.fetch(:token)
    @reset_url = params[:reset_url]
    mail(to: @user.email, subject: "Reset your Storytime password")
  end
end
