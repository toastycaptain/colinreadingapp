ActiveAdmin.register UsageEvent do
  actions :index, :show
  menu priority: 6

  config.sort_order = "occurred_at_desc"
  config.per_page = 100

  includes :child_profile, :book

  filter :occurred_at
  filter :book_publisher_id,
         as: :select,
         label: "Publisher",
         collection: proc { Publisher.order(:name).pluck(:name, :id) }
  filter :book
  filter :child_profile_id, as: :numeric
  filter :event_type, as: :select, collection: proc { UsageEvent.event_types.keys }

  index do
    id_column
    column :occurred_at
    column("Publisher") { |event| event.book.publisher&.name }
    column("Book") { |event| link_to(event.book.title, admin_book_path(event.book)) }
    column("Child") { |event| link_to(event.child_profile.name, admin_child_profile_path(event.child_profile)) }
    column :event_type
    column :position_seconds
    column :watched_seconds
    column :playback_session_id
    actions
  end

  csv do
    column :id
    column(:occurred_at)
    column(:publisher) { |event| event.book.publisher&.name }
    column(:book_id)
    column(:book_title) { |event| event.book.title }
    column(:child_profile_id)
    column(:event_type)
    column(:position_seconds)
    column(:watched_seconds)
    column(:playback_session_id)
    column(:client_event_id)
  end

  show do
    attributes_table do
      row :id
      row :occurred_at
      row :event_type
      row :child_profile
      row :book
      row :position_seconds
      row :watched_seconds
      row :playback_session_id
      row :client_event_id
      row :created_at
      row :updated_at
      row :metadata do |event|
        pre JSON.pretty_generate(event.metadata || {})
      end
    end
  end

  controller do
    def scoped_collection
      super.includes(:child_profile, book: :publisher)
    end

    def index
      if defined?(AuditLog)
        AuditLog.record!(
          actor: current_admin_user,
          action: "view_usage_events",
          metadata: { filters: params[:q].to_h, path: request.fullpath },
        )
      end

      super
    end

    def show
      if defined?(AuditLog)
        AuditLog.record!(
          actor: current_admin_user,
          action: "view_usage_event",
          subject: resource,
          metadata: { path: request.fullpath },
        )
      end

      super
    end
  end
end
