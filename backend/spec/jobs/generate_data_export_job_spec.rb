require "rails_helper"

RSpec.describe GenerateDataExportJob, type: :job do
  it "generates a scoped analytics csv and marks export ready" do
    publisher = create(:publisher)
    other_publisher = create(:publisher)
    book = create(:book, publisher: publisher, title: "Exported Book")
    other_book = create(:book, publisher: other_publisher, title: "Hidden Book")

    create(:daily_metric, publisher: publisher, book: book, metric_date: Date.current, minutes_watched: 12.5)
    create(:daily_metric, publisher: other_publisher, book: other_book, metric_date: Date.current, minutes_watched: 99.9)

    export = create(
      :data_export,
      requested_by: create(:admin_user),
      publisher: publisher,
      export_type: :analytics_daily,
      params: {
        "start_date" => Date.current.to_s,
        "end_date" => Date.current.to_s,
      },
    )

    described_class.perform_now(export.id)

    export.reload
    expect(export.status).to eq("ready")
    expect(export.file_path).to exist

    csv = File.read(export.file_path)
    expect(csv).to include("Exported Book")
    expect(csv).not_to include("Hidden Book")
  end
end
