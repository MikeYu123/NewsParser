require 'sidekiq'
require 'sidekiq/scheduler'

Dir[File.expand_path('../../workers/*.rb',__FILE__)].each do |file|
   load file
end

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'sidekiq_jobs', :size => 1 }
end

class HardWorker
  include Sidekiq::Worker
  def perform
  end
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'sidekiq_jobs' }
  config.on(:startup) do
    Sidekiq::Scheduler.enabled = true
    Sidekiq.schedule = YAML.load_file(File.expand_path("../schedule.yml", __FILE__))
    Sidekiq::Scheduler.reload_schedule!
  end
end
