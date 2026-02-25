# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: "Storytime Admin Dashboard" do
    active_books_count = Book.active.count
    processing_count = VideoAsset.processing.count
    failed_count = VideoAsset.failed.count
    recent_events = UsageEvent.where(occurred_at: 7.days.ago..Time.current)
    recent_minutes = recent_events.where(event_type: [UsageEvent.event_types["heartbeat"], UsageEvent.event_types["play_end"]]).sum(:position_seconds).to_f / 60.0
    recent_play_starts = recent_events.where(event_type: UsageEvent.event_types["play_start"]).count
    expiring_rights = RightsWindow.includes(:book, :publisher).where(end_at: Time.current..30.days.from_now).order(:end_at).limit(10)

    columns do
      column do
        panel "Catalog" do
          attributes_table_for(Book.new) do
            row("Active books") { active_books_count }
          end
        end

        panel "Video Processing Queue" do
          attributes_table_for(VideoAsset.new) do
            row("Processing") { status_tag(processing_count, class: "warning") }
            row("Failed") { status_tag(failed_count, class: (failed_count.positive? ? "error" : "ok")) }
          end
          div do
            link_to "View Video Assets", admin_video_assets_path
          end
        end
      end

      column do
        panel "Usage (Last 7 Days)" do
          attributes_table_for(UsageEvent.new) do
            row("Minutes watched") { format("%.2f", recent_minutes) }
            row("Play starts") { recent_play_starts }
          end
          div do
            link_to "Open Usage Reports", admin_usage_reports_path
          end
        end

        panel "Rights Expiring in 30 Days" do
          if expiring_rights.any?
            table_for expiring_rights do
              column("Book") { |rw| link_to(rw.book.title, admin_book_path(rw.book)) }
              column("Publisher") { |rw| rw.publisher.name }
              column("Territory", &:territory)
              column("Expires At") { |rw| rw.end_at.strftime("%Y-%m-%d") }
            end
          else
            div "No upcoming rights expirations."
          end
        end
      end
    end
  end
end
