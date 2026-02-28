class Publisher::BooksController < Publisher::BaseController
  before_action :require_analytics_access!
  before_action :set_book, only: :show

  def index
    @books = current_publisher.books.includes(:video_asset, :rights_windows).order(created_at: :desc)
  end

  def show
    @rights_windows = @book.rights_windows.order(start_at: :desc)
    @metrics = DailyMetric
      .where(publisher_id: current_publisher.id, book_id: @book.id)
      .where(metric_date: 30.days.ago.to_date..Date.current)
      .order(metric_date: :asc)
  end

  private

  def set_book
    @book = current_publisher.books.find(params[:id])
  end
end
