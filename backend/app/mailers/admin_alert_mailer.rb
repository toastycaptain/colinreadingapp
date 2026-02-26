class AdminAlertMailer < ApplicationMailer
  def generic_alert
    @subject = params.fetch(:subject)
    @body = params.fetch(:body)

    recipients = configured_recipients
    return if recipients.empty?

    mail(to: recipients, subject: "[Storytime] #{@subject}")
  end

  private

  def configured_recipients
    env_list = ENV["ADMIN_ALERT_EMAILS"].to_s.split(",").map(&:strip).reject(&:blank?)
    return env_list if env_list.any?

    AdminUser.where(role: [:super_admin, :finance_admin]).pluck(:email)
  end
end
