# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever


every 1.day, :at => '06:58' do
  rake "daily_job:send_notif_approval_so"
  rake "daily_job:send_notif_approval_grn"
end
every 1.day, :at => '11:58' do
  rake "daily_job:send_notif_approval_so"
  rake "daily_job:send_notif_approval_grn"
end
every 1.day, :at => '17:58' do
  rake "daily_job:send_notif_approval_so"
  rake "daily_job:send_notif_approval_grn"
end

every 1.day, :at => '07:00' do
  rake "daily_job:send_notif_approval_prf"
  # rake "daily_job:send_notif_approval_payreq"  
  # rake "daily_job:send_notif_approval_bpk"
end
every 1.day, :at => '07:02' do
  rake "daily_job:send_notif_approval_po"
end
every 1.day, :at => '12:00' do
  rake "daily_job:send_notif_approval_prf"
end
every 1.day, :at => '12:02' do
  rake "daily_job:send_notif_approval_po"
end
every 1.day, :at => '18:00' do
  rake "daily_job:send_notif_approval_prf"
  # rake "daily_job:send_notif_approval_payreq"
  # rake "daily_job:send_notif_approval_bpk"
end
every 1.day, :at => '18:02' do
  rake "daily_job:send_notif_approval_po"
end

every 1.day, :at => '18:30' do
  rake "backup:db"
end

every 1.day, :at => '04:00' do
  rake "backup:move_to_another_server"
end
every 1.day, :at => '13:00' do
  rake "backup:move_to_another_server"
end
every 1.day, :at => '19:00' do
  rake "backup:move_to_another_server"
end

every '15 00 * * 1-5' do
  rake "daily_job:routine_jobs"
end

# open stock WH
every 1.month, :at => '00:00' do
  rake "daily_job:open_stock[1,'P']"
end
every 1.month, :at => '00:01' do
  rake "daily_job:open_stock[1,'M']"
end
every 1.month, :at => '00:02' do
  rake "daily_job:open_stock[1,'G']"
end
every 1.month, :at => '00:03' do
  rake "daily_job:open_stock[1,'C']"
end
every 1.month, :at => '00:04' do
  rake "daily_job:open_stock[1,'E']"
end

# ET Routine [payment]
every 1.day, :at => '06:00' do
  rake "daily_job:routine_cost"
end

every 1.day, :at => '12:50' do
  rake "finance:cost_projects"
end

every 1.day, :at => '08:00' do
  rake "daily_job:send_notif_approval_spl"
end
every 1.day, :at => '08:05' do
  rake "daily_job:send_notif_approval_grn_approve2"
end