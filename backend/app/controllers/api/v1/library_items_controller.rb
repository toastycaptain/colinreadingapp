class Api::V1::LibraryItemsController < Api::V1::BaseController
  before_action :require_parent!
  before_action :set_child

  def create
    book = Book.active.find(params.require(:book_id))
    library_item = @child.library_items.create!(book: book, added_by_user: current_user)

    render json: {
      child_id: @child.id,
      book_id: library_item.book_id,
      created_at: library_item.created_at,
    }, status: :created
  rescue ActiveRecord::RecordNotUnique
    render_error(code: "already_exists", message: "Book already in child library", status: :conflict)
  end

  def destroy
    library_item = @child.library_items.find_by!(book_id: params[:book_id])
    library_item.destroy!
    head :no_content
  end

  private

  def set_child
    @child = current_user.child_profiles.find(params[:child_id])
  end
end
