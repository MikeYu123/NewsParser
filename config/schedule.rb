# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/CronI

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
every 2.hours do
  runner "GazetaRuParser.fetch_feed"
end
every 2.hours do
  runner "RbcParser.fetch_feed"
end
every 2.hours do
  runner "RiaRuParser.fetch_feed"
end
every 2.hours do
  runner "LentaParser.fetch_feed"
end
every 2.hours do
  runner "MeduzaParser.fetch_feed"
end
every 2.hours do
  runner "IzvestiaParser.fetch_feed"
end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
