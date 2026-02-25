class MuxClient
  def initialize(
    token_id: ENV.fetch("MUX_TOKEN_ID"),
    token_secret: ENV.fetch("MUX_TOKEN_SECRET"),
    cors_origin: nil
  )
    @token_id = token_id
    @token_secret = token_secret
    @cors_origin = cors_origin
  end

  def create_direct_upload(playback_policy: VideoAsset.playback_policies[:signed], passthrough: nil)
    configure!

    asset_settings = MuxRuby::CreateAssetRequest.new
    policy = playback_policy.is_a?(Integer) ? VideoAsset.playback_policies.key(playback_policy) : playback_policy.to_s
    policy = VideoAsset.playback_policies.key(VideoAsset.playback_policies[:signed]) if policy.blank?
    asset_settings.playback_policies = [policy]
    asset_settings.passthrough = passthrough if passthrough.present?

    request = MuxRuby::CreateUploadRequest.new(
      cors_origin: @cors_origin,
      new_asset_settings: asset_settings,
    )

    MuxRuby::DirectUploadsApi.new.create_direct_upload(request).data
  end

  def get_asset(asset_id)
    configure!
    MuxRuby::AssetsApi.new.get_asset(asset_id).data
  end

  private

  def configure!
    MuxRuby.configure do |config|
      config.username = @token_id
      config.password = @token_secret
    end
  end
end
