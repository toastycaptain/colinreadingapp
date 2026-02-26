class Api::V1::LibraryController < Api::V1::BaseController
  before_action :require_parent!
  before_action :set_child

  def index
    books = @child.books
      .joins(:library_items)
      .where(library_items: { child_profile_id: @child.id })
      .select("books.*, library_items.created_at AS library_added_at")
      .order("library_items.created_at DESC")

    render json: books.map { |book| serialize_book(book) }
  end

  private

  def set_child
    @child = current_user.child_profiles.find(params[:child_id])
  end

  def serialize_book(book)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      category: book.category,
      age_min: book.age_min,
      age_max: book.age_max,
      language: book.language,
      cover_image_url: book.cover_image_url,
      added_at: book.attributes["library_added_at"],
    }
  end
end
