ActiveAdmin.register PartnershipContract do
  permit_params :publisher_id, :contract_name, :start_date, :end_date, :payment_model,
                :rev_share_bps, :minimum_guarantee_cents, :notes, :status

  scope :all
  scope :draft
  scope :active
  scope :expired
  scope :terminated

  index do
    selectable_column
    id_column
    column :publisher
    column :contract_name
    column :payment_model
    column :rev_share_bps
    column :minimum_guarantee_cents
    column :status
    column :start_date
    column :end_date
    actions
  end

  filter :publisher
  filter :contract_name
  filter :payment_model
  filter :status
  filter :start_date
  filter :end_date

  form do |f|
    f.inputs do
      f.input :publisher
      f.input :contract_name
      f.input :start_date, as: :date_select
      f.input :end_date, as: :date_select
      f.input :payment_model
      f.input :rev_share_bps, hint: "Required when payment model includes revenue share"
      f.input :minimum_guarantee_cents
      f.input :notes
      f.input :status
    end
    f.actions
  end
end
