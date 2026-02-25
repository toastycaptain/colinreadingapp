require "rails_helper"

RSpec.describe MediaConvertCreateJob, type: :job do
  it "stores the MediaConvert job id and moves asset to processing" do
    video_asset = create(:video_asset, processing_status: :uploaded)
    service = instance_double(MediaConvertService, create_hls_job: "1678901234567-abcd")

    allow(MediaConvertService).to receive(:new).and_return(service)

    described_class.perform_now(video_asset.id)

    video_asset.reload
    expect(video_asset.mediaconvert_job_id).to eq("1678901234567-abcd")
    expect(video_asset.processing_status).to eq("processing")
  end
end
