ActiveAdmin.register_page "Analytics Dashboard" do
  menu priority: 8

  content title: "Analytics Dashboard" do
    start_date = params[:start].presence || 30.days.ago.to_date.to_s
    end_date = params[:end].presence || Date.current.to_s
    publisher_id = params[:publisher_id].presence
    book_id = params[:book_id].presence

    metrics = DailyMetric
      .includes(:publisher, :book)
      .where(metric_date: Date.parse(start_date)..Date.parse(end_date))
    metrics = metrics.where(publisher_id: publisher_id) if publisher_id.present?
    metrics = metrics.where(book_id: book_id) if book_id.present?
    metrics = metrics.order(metric_date: :desc, minutes_watched: :desc)

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
            div do
              input type: "submit", value: "Apply"
            end
          end
        end
      end
    end

    panel "Summary" do
      attributes_table_for(DailyMetric.new) do
        row("Rows") { metrics.count }
        row("Total minutes watched") { format("%.2f", metrics.sum(:minutes_watched).to_f) }
        row("Average completion") do
          average = metrics.average(:avg_completion_rate).to_f
          "#{(average * 100).round(2)}%"
        end
      end
    end

    panel "Daily Metrics" do
      table_for metrics.limit(300) do
        column("Date", &:metric_date)
        column("Publisher") { |row| row.publisher&.name }
        column("Book") { |row| row.book&.title }
        column("Minutes") { |row| format("%.2f", row.minutes_watched.to_f) }
        column("Play Starts", &:play_starts)
        column("Play Ends", &:play_ends)
        column("Unique Children", &:unique_children)
        column("Completion") { |row| "#{(row.avg_completion_rate.to_f * 100).round(2)}%" }
      end
    end
  end
end
