class ProcessStripePayoutJob < ApplicationJob
  queue_as :payouts

  def perform(payout_period_id)
    payout_period = PayoutPeriod.find(payout_period_id)
    statements = payout_period.publisher_statements.where(status: [:approved, :failed])

    if ENV["STRIPE_SECRET_KEY"].blank?
      mark_as_paid_without_transfer!(payout_period, statements)
      return
    end

    Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")

    payout_period.update!(notes: nil)

    statements.find_each do |statement|
      publish_to_stripe!(statement)
    rescue StandardError => e
      statement.update!(status: :failed)
      payout_period.update!(notes: [payout_period.notes, "Publisher ##{statement.publisher_id}: #{e.message}"].compact.join("\n").truncate(1000))
      AdminAlertMailer.with(subject: "Stripe payout failed", body: e.message).generic_alert.deliver_later
    end

    if payout_period.publisher_statements.where(status: :failed).exists?
      payout_period.update!(status: :failed)
    else
      payout_period.update!(status: :paid, paid_at: Time.current)
    end
  end

  private

  def mark_as_paid_without_transfer!(payout_period, statements)
    statements.update_all(status: PublisherStatement.statuses.fetch("paid"))
    payout_period.update!(status: :paid, paid_at: Time.current)
  end

  def publish_to_stripe!(statement)
    publisher = statement.publisher

    unless publisher.stripe_connect_account_id.present? && publisher.stripe_onboarding_complete?
      raise "Publisher #{publisher.id} is not fully onboarded to Stripe Connect"
    end

    if statement.payout_amount_cents <= 0
      statement.update!(status: :paid)
      return
    end

    transfer = Stripe::Transfer.create(
      {
        amount: statement.payout_amount_cents,
        currency: statement.payout_period.currency.downcase,
        destination: publisher.stripe_connect_account_id,
        metadata: {
          payout_period_id: statement.payout_period_id,
          publisher_statement_id: statement.id,
          publisher_id: publisher.id,
        },
      }
    )

    statement.update!(status: :paid, stripe_transfer_id: transfer.id)
  end
end
