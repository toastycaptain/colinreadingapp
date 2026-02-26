class Api::V1::Catalog::BooksController < Api::V1::BaseController
  before_action :require_parent!

  def index
    books = Book.active.includes(:publisher).search(params[:q])

    if params[:age].present?
      age = params[:age].to_i
      books = books.where("COALESCE(age_min, 0) <= ? AND (age_max IS NULL OR age_max >= ?)", age, age)
    end

    books = books.where(publisher_id: params[:publisher]) if params[:publisher].present?
    books = books.where(category: params[:category]) if params[:category].present?

    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min

    total_count = books.count
    paginated_books = books.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: paginated_books.map do |book|
        {
          id: book.id,
          title: book.title,
          author: book.author,
          description: book.description,
          age_min: book.age_min,
          age_max: book.age_max,
          category: book.category,
          language: book.language,
          cover_image_url: book.cover_image_url,
          publisher: book.publisher&.slice(:id, :name),
          status: book.status,
        }
      end,
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
      },
    }
  end

  def show
    book = Book.active.includes(:publisher).find(params[:id])

    render json: serialize_book(book)
  end

  private

  def serialize_book(book)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      age_min: book.age_min,
      age_max: book.age_max,
      category: book.category,
      language: book.language,
      cover_image_url: book.cover_image_url,
      publisher: book.publisher&.slice(:id, :name),
      status: book.status,
      video_asset: {
        processing_status: book.video_asset&.processing_status,
        duration_seconds: book.video_asset&.duration_seconds,
      },
    }
  end
end
