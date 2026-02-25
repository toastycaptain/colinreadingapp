class Api::V1::PlaybackSessionsController < Api::V1::BaseController
  before_action :require_parent!
  before_action :set_child

  def create
    book = Book.find(params.require(:book_id))

    unless @child.books.exists?(book.id)
      return render_error(
        code: "book_not_in_library",
        message: "Book is not assigned to this child",
        status: :forbidden,
      )
    end

    unless book.rights_windows.active_at(Time.current).exists?
      return render_error(
        code: "rights_expired",
        message: "Playback is not currently licensed",
        status: :forbidden,
      )
    end

    video_asset = book.video_asset
    unless video_asset&.ready? && video_asset.mux_playback_id.present?
      return render_error(
        code: "asset_not_ready",
        message: "Video asset is not ready",
        status: :unprocessable_entity,
      )
    end

    expires_at = 5.minutes.from_now
    playback_id = video_asset.mux_playback_id
    playback_token = MuxSigning.new.token_for(playback_id, exp: expires_at)
    playback_hls_url = "https://stream.mux.com/#{playback_id}.m3u8"

    PlaybackSession.create!(
      child_profile: @child,
      book: book,
      issued_at: Time.current,
      expires_at: expires_at,
    )

    render json: {
      playback_hls_url: playback_hls_url,
      playback_token: playback_token,
      expires_at: expires_at.iso8601,
    }
  end

  private

  def set_child
    @child = current_user.child_profiles.find(params[:child_id])
  end
end
