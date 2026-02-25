ActiveAdmin.register RightsWindow do
  permit_params :publisher_id, :book_id, :start_at, :end_at, :territory

  index do
    selectable_column
    id_column
    column :publisher
    column :book
    column :territory
    column :start_at
    column :end_at
    actions
  end

  filter :publisher
  filter :book
  filter :territory
  filter :start_at
  filter :end_at

  form do |f|
    f.inputs do
      f.input :publisher
      f.input :book
      f.input :territory
      f.input :start_at, as: :datetime_select
      f.input :end_at, as: :datetime_select
    end
    f.actions
  end
end
