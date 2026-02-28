ActiveAdmin.register_page "Analytics Dashboard" do
  menu priority: 8

  content title: "Analytics Dashboard" do
    start_date = params[:start].presence || 30.days.ago.to_date.to_s
    end_date = params[:end].presence || Date.current.to_s
    publisher_id = params[:publisher_id].presence
    book_id = params[:book_id].presence
    child_profile_id = params[:child_profile_id].presence
    can_view_child_data = current_admin_user&.can_manage_support?

    base_scope = UsageEvent.where(
      occurred_at: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day,
    )
    base_scope = base_scope.where(book_id: book_id) if book_id.present?
    if publisher_id.present?
      base_scope = base_scope.where(book_id: Book.where(publisher_id: publisher_id).select(:id))
    end
    if child_profile_id.present? && can_view_child_data
      base_scope = base_scope.where(child_profile_id: child_profile_id)
    end

    watched_scope = WatchedSecondsQuery.relation(base_scope)

    total_watched_seconds = watched_scope.sum("usage_events.computed_watched_seconds")
    play_start_id = UsageEvent.event_types.fetch("play_start")
    play_end_id = UsageEvent.event_types.fetch("play_end")
    play_starts = base_scope.where(event_type: play_start_id).count
    play_ends = base_scope.where(event_type: play_end_id).count
    active_children = base_scope.select(:child_profile_id).distinct.count

    avg_completion_rate = base_scope
      .joins(book: :video_asset)
      .where(event_type: play_end_id)
      .where("video_assets.duration_seconds > 0")
      .average("LEAST(usage_events.position_seconds::numeric / video_assets.duration_seconds, 1.0)")
      .to_f

    minutes_by_day = watched_scope
      .select(
        "DATE(usage_events.occurred_at) AS report_date",
        "SUM(usage_events.computed_watched_seconds) AS watched_seconds",
      )
      .group("DATE(usage_events.occurred_at)")
      .order("report_date ASC")

    unique_children_by_day = base_scope
      .group("DATE(usage_events.occurred_at)")
      .distinct
      .count(:child_profile_id)

    top_books = watched_scope
      .joins("INNER JOIN books ON books.id = usage_events.book_id")
      .joins("LEFT JOIN publishers ON publishers.id = books.publisher_id")
      .group("books.id", "books.title", "publishers.id", "publishers.name")
      .select(
        "books.id AS book_id",
        "books.title AS book_title",
        "publishers.id AS publisher_id",
        "publishers.name AS publisher_name",
        "SUM(usage_events.computed_watched_seconds) AS watched_seconds",
        "COUNT(DISTINCT usage_events.child_profile_id) AS unique_children",
      )
      .order("watched_seconds DESC")
      .limit(10)

    top_children = if can_view_child_data
      watched_scope
        .joins("INNER JOIN child_profiles ON child_profiles.id = usage_events.child_profile_id")
        .joins("INNER JOIN users ON users.id = child_profiles.user_id")
        .group("child_profiles.id", "child_profiles.name", "users.email")
        .select(
          "child_profiles.id AS child_profile_id",
          "child_profiles.name AS child_name",
          "users.email AS parent_email",
          "SUM(usage_events.computed_watched_seconds) AS watched_seconds",
        )
        .order("watched_seconds DESC")
        .limit(10)
    else
      []
    end

    panel "Filters" do
      div do
        form action: admin_analytics_dashboard_path, method: :get do
          div style: "display:flex; gap: 12px; flex-wrap: wrap; align-items: flex-end;" do
            div do
              label "Start date", for: "start"
              input type: "date", name: "start", value: start_date
            end
            div do
              label "End date", for: "end"
              input type: "date", name: "end", value: end_date
            end
            div do
              label "Publisher", for: "publisher_id"
              select name: "publisher_id" do
                option value: "" do
                  "All"
                end
                Publisher.order(:name).each do |publisher|
                  option value: publisher.id, selected: (publisher.id.to_s == publisher_id) do
                    publisher.name
                  end
                end
              end
            end
            div do
              label "Book", for: "book_id"
              select name: "book_id" do
                option value: "" do
                  "All"
                end
                Book.order(:title).each do |book|
                  option value: book.id, selected: (book.id.to_s == book_id) do
                    book.title
                  end
                end
              end
            end
            if can_view_child_data
              div do
                label "Child Profile ID", for: "child_profile_id"
                input type: "number", name: "child_profile_id", value: child_profile_id
              end
            end
            div do
              input type: "submit", value: "Apply"
            end
          end
        end
      end
    end

    panel "Summary KPIs" do
      attributes_table_for DailyMetric.new do
        row("Minutes watched") { format("%.2f", total_watched_seconds.to_f / 60.0) }
        row("Active children") { active_children }
        row("Play starts") { play_starts }
        row("Play ends") { play_ends }
        row("Avg completion rate") { "#{(avg_completion_rate * 100).round(2)}%" }
      end
    end

    panel "Minutes Watched Over Time" do
      rows = minutes_by_day.map do |metric|
        { date: metric.report_date, minutes: metric.watched_seconds.to_f / 60.0 }
      end
      max_minutes = [rows.map { |row| row[:minutes] }.max.to_f, 1.0].max

      if rows.empty?
        div "No data for selected filters."
      else
        table_for rows do
          column("Date") { |row| row[:date] }
          column("Minutes") { |row| format("%.2f", row[:minutes]) }
          column("Chart") do |row|
            width = ((row[:minutes] / max_minutes) * 240.0).round
            div style: "background:#2563eb; height:10px; width:#{width}px; border-radius:4px;" do
            end
          end
        end
      end
    end

    panel "Unique Children Over Time" do
      rows = unique_children_by_day.sort_by { |date, _| date }.map { |date, count| { date: date, count: count } }
      max_count = [rows.map { |row| row[:count] }.max.to_i, 1].max

      if rows.empty?
        div "No data for selected filters."
      else
        table_for rows do
          column("Date") { |row| row[:date] }
          column("Unique children") { |row| row[:count] }
          column("Chart") do |row|
            width = ((row[:count].to_f / max_count) * 240.0).round
            div style: "background:#16a34a; height:10px; width:#{width}px; border-radius:4px;" do
            end
          end
        end
      end
    end

    panel "Top Books by Minutes Watched" do
      if top_books.empty?
        div "No books found for selected filters."
      else
        table_for top_books do
          column("Book") do |row|
            link_to row.book_title, admin_book_path(row.book_id)
          end
          column("Publisher") do |row|
            if row.publisher_id.present?
              link_to row.publisher_name, admin_publisher_path(row.publisher_id)
            else
              "Unassigned"
            end
          end
          column("Minutes watched") { |row| format("%.2f", row.watched_seconds.to_f / 60.0) }
          column("Unique children", &:unique_children)
          column("Drilldown") do |row|
            link_to "Book analytics", admin_analytics_dashboard_path(
              start: start_date,
              end: end_date,
              publisher_id: publisher_id,
              book_id: row.book_id,
            )
          end
        end
      end
    end

    if can_view_child_data
      panel "Top Children by Watch Time" do
        if top_children.empty?
          div "No child-level data for selected filters."
        else
          table_for top_children do
            column("Child") { |row| link_to(row.child_name, admin_child_profile_path(row.child_profile_id)) }
            column("Parent Email", &:parent_email)
            column("Minutes watched") { |row| format("%.2f", row.watched_seconds.to_f / 60.0) }
            column("Drilldown") do |row|
              link_to "Child analytics", admin_analytics_dashboard_path(
                start: start_date,
                end: end_date,
                publisher_id: publisher_id,
                book_id: book_id,
                child_profile_id: row.child_profile_id,
              )
            end
          end
        end
      end
    end
  end
end
