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
    unless video_asset&.ready?
      return render_error(
        code: "asset_not_ready",
        message: "Video asset is not ready",
        status: :unprocessable_entity,
      )
    end

    expires_at = 5.minutes.from_now
    signer = CloudfrontSignedCookieService.new(
      cloudfront_domain: ENV.fetch("CLOUDFRONT_DOMAIN"),
      key_pair_id: ENV.fetch("CLOUDFRONT_KEY_PAIR_ID"),
      private_key_pem: CloudfrontPrivateKeyResolver.call,
    )

    signed = signer.generate_for_book(book_id: book.id, expires_at: expires_at)

    manifest_path = video_asset.hls_manifest_path.presence || "books/#{book.id}/hls/index.m3u8"
    playback_url = "https://#{ENV.fetch('CLOUDFRONT_DOMAIN')}/#{manifest_path}"

    PlaybackSession.create!(
      child_profile: @child,
      book: book,
      issued_at: Time.current,
      expires_at: expires_at,
      cloudfront_policy: signed[:policy],
    )

    render json: {
      playback_manifest_url: playback_url,
      cookies: signed[:cookies],
      expires_at: expires_at.iso8601,
    }
  end

  private

  def set_child
    @child = current_user.child_profiles.find(params[:child_id])
  end
end
