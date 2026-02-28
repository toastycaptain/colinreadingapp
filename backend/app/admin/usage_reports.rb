ActiveAdmin.register_page "Usage Reports" do
  menu priority: 7

  content title: "Usage Reports" do
    start_date = params[:start].presence || 30.days.ago.to_date.to_s
    end_date = params[:end].presence || Date.current.to_s
    publisher_id = params[:publisher_id].presence
    book_id = params[:book_id].presence
    child_profile_id = params[:child_profile_id].presence
    can_view_child_data = current_admin_user&.can_manage_support?

    rows = UsageReportQuery.new(
      start_date: Date.parse(start_date),
      end_date: Date.parse(end_date),
      publisher_id: publisher_id,
      book_id: book_id,
      child_profile_id: (can_view_child_data ? child_profile_id : nil),
    ).call

    panel "Filters" do
      div do
        form action: admin_usage_reports_path, method: :get do |f|
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
            div do
              csv_url = "/admin/api/v1/reports/usage.csv?start=#{start_date}&end=#{end_date}"
              csv_url += "&publisher_id=#{publisher_id}" if publisher_id.present?
              csv_url += "&book_id=#{book_id}" if book_id.present?
              csv_url += "&child_profile_id=#{child_profile_id}" if child_profile_id.present? && can_view_child_data
              a "Export CSV", href: csv_url, class: "button"
            end
          end
        end
      end
    end

    panel "Results" do
      if rows.empty?
        div "No usage rows found for the selected filters."
      else
        table_for rows do
          column("Date") { |row| row[:date] }
          column("Publisher") { |row| row[:publisher_name] }
          column("Book ID") { |row| row[:book_id] }
          column("Book Title") { |row| row[:book_title] }
          column("Minutes Watched") { |row| format("%.2f", row[:minutes_watched]) }
          column("Play Starts") { |row| row[:play_starts] }
          column("Play Ends") { |row| row[:play_ends] }
          column("Unique Children") { |row| row[:unique_children] }
        end
      end
    end
  end
end
