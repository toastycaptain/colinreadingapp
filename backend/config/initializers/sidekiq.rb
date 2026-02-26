redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  schedule_path = Rails.root.join("config/sidekiq_schedule.yml")
  if schedule_path.exist?
    begin
      require "sidekiq/cron/job"
      schedule_hash = YAML.load_file(schedule_path)
      Sidekiq::Cron::Job.load_from_hash(schedule_hash) if schedule_hash.present?
    rescue StandardError => e
      Rails.logger.error("[Sidekiq] Failed to load cron schedule: #{e.class} #{e.message}")
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
