class MediaConvertService
  HLS_OUTPUT_GROUP_NAME = "HLS".freeze

  def initialize(region: ENV.fetch("AWS_REGION"), role_arn: ENV.fetch("MEDIACONVERT_ROLE_ARN"), endpoint_url: ENV["MEDIACONVERT_ENDPOINT_URL"])
    @region = region
    @role_arn = role_arn
    @endpoint_url = endpoint_url
  end

  def create_hls_job(video_asset)
    response = client.create_job(
      role: @role_arn,
      settings: {
        inputs: [
          {
            file_input: "s3://#{ENV.fetch('S3_MASTER_BUCKET')}/#{video_asset.master_s3_key}",
          },
        ],
        output_groups: [
          {
            name: HLS_OUTPUT_GROUP_NAME,
            output_group_settings: {
              type: "HLS_GROUP_SETTINGS",
              hls_group_settings: {
                destination: "s3://#{ENV.fetch('S3_HLS_BUCKET')}/books/#{video_asset.book_id}/hls/",
                segment_length: 6,
                min_segment_length: 0,
                manifest_duration_format: "INTEGER",
              },
            },
            outputs: [
              {
                container_settings: { container: "M3U8" },
                video_description: {
                  codec_settings: {
                    codec: "H_264",
                    h264_settings: {
                      max_bitrate: 5_000_000,
                      rate_control_mode: "QVBR",
                      scene_change_detect: "TRANSITION_DETECTION",
                    },
                  },
                },
                audio_descriptions: [
                  {
                    codec_settings: {
                      codec: "AAC",
                      aac_settings: {
                        bitrate: 96_000,
                        coding_mode: "CODING_MODE_2_0",
                        sample_rate: 48_000,
                      },
                    },
                  },
                ],
                name_modifier: "-main",
              },
            ],
          },
        ],
      },
      status_update_interval: "SECONDS_60",
    )

    response.job.id
  end

  def job_status(job_id)
    client.get_job(id: job_id).job.status
  end

  private

  def client
    @client ||= Aws::MediaConvert::Client.new(
      region: @region,
      endpoint: resolved_endpoint,
    )
  end

  def resolved_endpoint
    @resolved_endpoint ||= begin
      if @endpoint_url.present?
        @endpoint_url
      else
        discovery_client = Aws::MediaConvert::Client.new(region: @region)
        discovery_client.describe_endpoints(max_results: 1).endpoints.first.url
      end
    end
  end
end
