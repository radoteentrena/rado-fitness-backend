# Whenever cron schedule configuration
# Update crontab with: bundle exec whenever --update-crontab
# View current crontab: bundle exec whenever
# Clear crontab: bundle exec whenever --clear-crontab

set :environment, 'production'
set :output, 'log/cron.log'

# Daily dunning job: send payment reminders and lock access for overdue users
# Runs at 10 AM UTC daily
every 1.day, at: '10:00 am' do
  runner 'SubscriptionDunningJob.perform_later'
end
