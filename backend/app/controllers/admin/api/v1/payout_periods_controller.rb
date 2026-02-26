class Admin::Api::V1::PayoutPeriodsController < Admin::Api::V1::BaseController
  before_action :require_finance_admin!
  before_action :set_payout_period, only: [:show, :generate_statements, :mark_paid]

  def create
    payout_period = PayoutPeriod.create!(payout_period_params)

    render json: serialize(payout_period), status: :created
  end

  def show
    render json: serialize(@payout_period, include_statements: true)
  end

  def generate_statements
    GeneratePayoutStatementsJob.perform_later(@payout_period.id)

    @payout_period.update!(status: :calculating)
    render json: { status: "enqueued", payout_period_id: @payout_period.id }
  end

  def mark_paid
    if params[:use_stripe].to_s == "true"
      ProcessStripePayoutJob.perform_later(@payout_period.id)
      render json: { status: "enqueued", payout_period_id: @payout_period.id }
    else
      @payout_period.publisher_statements.update_all(status: PublisherStatement.statuses.fetch("paid"))
      @payout_period.update!(status: :paid, paid_at: Time.current)
      render json: serialize(@payout_period, include_statements: true)
    end
  end

  private

  def set_payout_period
    @payout_period = PayoutPeriod.find(params[:id])
  end

  def payout_period_params
    params.permit(:start_date, :end_date, :currency, :notes)
  end

  def serialize(period, include_statements: false)
    payload = period.as_json(
      only: [
        :id,
        :start_date,
        :end_date,
        :currency,
        :status,
        :total_gross_revenue_cents,
        :total_payout_cents,
        :calculated_at,
        :paid_at,
        :notes,
      ]
    )

    if include_statements
      payload[:publisher_statements] = period.publisher_statements.includes(:publisher).map do |statement|
        statement.as_json(
          only: [
            :id,
            :publisher_id,
            :status,
            :minutes_watched,
            :play_starts,
            :play_ends,
            :unique_children,
            :gross_revenue_cents,
            :platform_fee_cents,
            :net_revenue_cents,
            :rev_share_bps,
            :payout_amount_cents,
            :stripe_transfer_id,
          ],
          methods: [],
        ).merge(publisher_name: statement.publisher.name)
      end
    end

    payload
  end
end
