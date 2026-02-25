class Admin::Api::V1::UploadsController < Admin::Api::V1::BaseController
  before_action :require_content_admin!

  def master_video
    book = Book.find(params.require(:book_id))
    filename = params[:filename].presence || "upload.mp4"
    content_type = params[:content_type].presence || "video/mp4"

    key = [
      "books",
      book.id,
      "master",
      "#{Time.current.strftime('%Y-%m-%d')}_#{sanitize_filename(filename)}",
    ].join("/")

    client = Aws::S3::Client.new(region: ENV.fetch("AWS_REGION"))
    bucket = Aws::S3::Resource.new(client: client).bucket(ENV.fetch("S3_MASTER_BUCKET"))
    presigned_post = bucket.presigned_post(
      key: key,
      content_type: content_type,
      expires: 900,
      success_action_status: "201",
    )

    render json: {
      url: presigned_post.url,
      fields: presigned_post.fields,
      key: key,
      expires_in: 900,
    }
  end

  private

  def sanitize_filename(filename)
    filename.gsub(/[^a-zA-Z0-9._-]/, "_")
  end
end
