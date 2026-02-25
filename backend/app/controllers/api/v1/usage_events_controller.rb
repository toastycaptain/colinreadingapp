class Api::V1::UsageEventsController < Api::V1::BaseController
  before_action :require_parent!

  def create
    child = current_user.child_profiles.find(params.require(:child_id))
    book = Book.find(params.require(:book_id))

    unless child.books.exists?(book.id)
      return render_error(
        code: "book_not_in_library",
        message: "Book is not assigned to this child",
        status: :forbidden,
      )
    end

    usage_event = UsageEvent.create!(
      child_profile: child,
      book: book,
      event_type: params.require(:event_type),
      position_seconds: params[:position_seconds],
      occurred_at: params[:occurred_at] || Time.current,
      metadata: params[:metadata] || {},
    )

    render json: usage_event.as_json(only: %i[id child_profile_id book_id event_type position_seconds occurred_at]), status: :created
  end
end
