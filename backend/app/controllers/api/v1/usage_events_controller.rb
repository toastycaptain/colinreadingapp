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

    playback_session = resolve_playback_session(child, book)
    usage_event, created = create_usage_event(child: child, book: book, playback_session: playback_session)

    render json: usage_event_payload(usage_event), status: created ? :created : :ok
  end

  private

  def usage_event_params
    params.permit(
      :event_type,
      :position_seconds,
      :occurred_at,
      :watched_seconds,
      :playback_session_id,
      :client_event_id,
      metadata: {},
    )
  end

  def resolve_playback_session(child, book)
    return nil if usage_event_params[:playback_session_id].blank?

    child.playback_sessions.where(book: book).find(usage_event_params[:playback_session_id])
  end

  def create_usage_event(child:, book:, playback_session:)
    attrs = {
      child_profile: child,
      book: book,
      playback_session: playback_session,
      event_type: params.require(:event_type),
      position_seconds: usage_event_params[:position_seconds],
      watched_seconds: usage_event_params[:watched_seconds],
      client_event_id: usage_event_params[:client_event_id],
      occurred_at: usage_event_params[:occurred_at] || Time.current,
      metadata: usage_event_params[:metadata] || {},
    }

    if attrs[:client_event_id].present?
      existing = UsageEvent.find_by(client_event_id: attrs[:client_event_id])
      return [existing, false] if existing
    end

    [UsageEvent.create!(attrs), true]
  rescue ActiveRecord::RecordNotUnique
    [UsageEvent.find_by!(client_event_id: attrs[:client_event_id]), false]
  end

  def usage_event_payload(event)
    event.as_json(
      only: %i[
        id child_profile_id book_id playback_session_id event_type position_seconds watched_seconds client_event_id occurred_at
      ],
    )
  end
end
