ActiveAdmin.register ChildProfile do
  actions :index, :show
  menu priority: 5

  config.sort_order = "created_at_desc"
  config.per_page = 50

  includes :user, :books

  index do
    id_column
    column :name
    column("Parent") { |child| link_to(child.user.email, admin_parent_path(child.user)) }
    column("Books in Library") { |child| child.books.size }
    column :created_at
    actions
  end

  filter :id
  filter :name
  filter :user_email, as: :string
  filter :created_at

  show do
    watched_7_days = WatchedSecondsQuery
      .relation(child_profile.usage_events.where(occurred_at: 7.days.ago..Time.current))
      .sum("usage_events.computed_watched_seconds")

    watched_30_days = WatchedSecondsQuery
      .relation(child_profile.usage_events.where(occurred_at: 30.days.ago..Time.current))
      .sum("usage_events.computed_watched_seconds")

    top_books = WatchedSecondsQuery
      .relation(child_profile.usage_events.where(occurred_at: 30.days.ago..Time.current))
      .joins("INNER JOIN books ON books.id = usage_events.book_id")
      .group("books.id", "books.title")
      .select("books.id AS book_id", "books.title AS book_title", "SUM(usage_events.computed_watched_seconds) AS watched_seconds")
      .order("watched_seconds DESC")
      .limit(5)

    recent_events = WatchedSecondsQuery
      .relation(child_profile.usage_events.where(occurred_at: 30.days.ago..Time.current))
      .joins(:book)
      .order("usage_events.occurred_at DESC, usage_events.id DESC")
      .limit(40)

    attributes_table do
      row :id
      row :name
      row("Parent") { |child| link_to(child.user.email, admin_parent_path(child.user)) }
      row :avatar_url
      row :created_at
      row :updated_at
    end

    panel "Watch Summary" do
      attributes_table_for child_profile do
        row("Minutes watched (7 days)") { format("%.2f", watched_7_days.to_f / 60.0) }
        row("Minutes watched (30 days)") { format("%.2f", watched_30_days.to_f / 60.0) }
        row("Most watched books (30 days)") do
          if top_books.any?
            top_books.map { |row| "#{row.book_title} (#{format('%.2f', row.watched_seconds.to_f / 60.0)}m)" }.join(", ")
          else
            "No watch activity"
          end
        end
      end
    end

    panel "Library" do
      table_for child_profile.library_items.includes(:book).order(created_at: :desc) do
        column(:book) { |item| link_to(item.book.title, admin_book_path(item.book)) }
        column("Author") { |item| item.book.author }
        column("Added At", &:created_at)
      end
    end

    panel "Recent Watch History (Last 30 Days)" do
      if recent_events.empty?
        div "No usage events for this child profile."
      else
        table_for recent_events do
          column("Time") { |event| event.occurred_at }
          column("Book") { |event| link_to(event.book.title, admin_book_path(event.book)) }
          column("Event Type", &:event_type)
          column("Position (s)", &:position_seconds)
          column("Watched (s)") { |event| event.attributes["computed_watched_seconds"].to_i }
          column("Session ID", &:playback_session_id)
        end
      end
    end
  end

  controller do
    def scoped_collection
      super.includes(:user, :books)
    end

    def show
      if defined?(AuditLog)
        AuditLog.record!(
          actor: current_admin_user,
          action: "view_child_profile",
          subject: resource,
          metadata: { path: request.fullpath },
        )
      end

      super
    end
  end
end
