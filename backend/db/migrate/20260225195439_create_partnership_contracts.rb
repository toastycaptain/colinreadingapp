class CreatePartnershipContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :partnership_contracts do |t|
      t.references :publisher, null: false, foreign_key: true
      t.string :contract_name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :payment_model, null: false, default: 0
      t.integer :rev_share_bps, null: false, default: 0
      t.integer :minimum_guarantee_cents
      t.text :notes
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :partnership_contracts, [:publisher_id, :status]
    add_index :partnership_contracts, :end_date
  end
end
