
namespace :backup do
  desc "Backup database"
  task :db => :environment do | t, args|
    RAILS_ENV = "development" if !defined?(RAILS_ENV)
    app_root = File.join(File.dirname(__FILE__), "..", "..")
    
    settings = YAML.load(File.read(File.join(app_root, "config", "database.yml")))[RAILS_ENV]
    dir_name = Time.now.strftime('%Y%m%d')

    path = File.join(app_root,"..","..","backup_db", "erp_provital", "#{dir_name}")
    f_name = "#{settings['database']}-#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql.gz"
    output_file = File.join(path, f_name)
    begin
      system("/bin/mkdir -p #{path} && /usr/bin/env mysqldump -P #{settings['port']} -h #{settings['host']} -u #{settings['username']} -p#{settings['password']} --force --opt --events --routines --triggers --databases #{settings['database']} | gzip -9 -c > #{output_file} ")
      
      puts "Backup Successfull : #{f_name}"
      # move_backup_db(path, f_name)

       # system("sshpass -p #{settings['password_scp']} scp -o 'StrictHostKeyChecking no' -r  /home/railsuser/backup_db/sip/#{Time.now.strftime('%Y%m%d')} #{settings['user_scp']}@192.168.131.225:/home/aden/backup_db/sip")
       # system("sshpass -p #{settings['password_scp']} scp -o 'StrictHostKeyChecking no' -r  /home/railsuser/backup_db/sip/#{Time.now.strftime('%Y%m%d')} #{settings['user_scp']}@192.168.121.199:/home/aden/backup_db/sip")
     

      #puts settings.inspect

      # list_mail = ["aden.pribadi@gmail.com","noreply@techno.co.id"]  
      # subject_mail = "[info] - Backup db berhasil #{Time.now.strftime('%Y%m%d_%H%M%S')}" 
      # content_mail = "lapor Bos, Backup db berhasil"
      # list_mail.each {|amail| UserMailer.tiki(amail, subject_mail, content_mail, nil).deliver! }

    rescue StandardError => error
      puts error
      # require 'telegram/bot' 
      # # TechnoIndonesia_bot
      # # puts "sip"
      # token = '688060970:AAEE5Ypc2dE3q0oj-tIYaxgkMEQ0q_SA3Gg'

      # Telegram::Bot::Client.run(token) do |bot|
        
      #   SysTelegram.where(:status=> 'active', :id=> [1,3,4]).each do |record|
      #     bot.api.send_message(chat_id: record.telegram_id, text: "Lapor Boss!, Gagal Backup Database nih : #{error.first(100)}", token: token)
      #   end

      #   # system "kill -9 #{Process.pid}"
      # end
    end
  end

  def move_backup_db(path, f_name)
    require 'net/scp'

    output_file = File.join(path, f_name)
    remote_path = "/share/IT/Backup/DB/PROVITAL"

    # upload a file to a remote server
    Net::SCP.upload!("cloud.tri-saudara.com", "admin",
      "#{output_file}", "#{remote_path}",
      :ssh => { :password => "typeANYw0rdSAJAb1sa"} )

    # # download a file from a remote server
    # Net::SCP.download!("remote.host.com", "username",
    #   "/remote/path", "/local/path",
    #   :password => password)

    # # download a file to an in-memory buffer
    # data = Net::SCP::download!("remote.host.com", "username", "/remote/path")
  end


  task :move_to_another_server => :environment do |t, args|
    puts "move_backup_file"
    my_paths = backup_list(["erp_provital", "sip_tarafis", "sip"])
    require 'net/scp'

    my_paths.each do |my_path|
      # puts "my_path: #{my_path}"
       # upload a file to a remote server
      Net::SCP.upload!("cloud.tri-saudara.com", "admin",
        "#{my_path[:local_path]}", "#{my_path[:remote_path]}",
        :ssh => { :password => "typeANYw0rdSAJAb1sa"} )
    end if my_paths.present? 
  end

  def backup_list(my_apps)
    result = []

    my_apps.each do |app_name|
      # puts app_name
      remote_path = "/share/IT/Backup/DB/#{app_name}"
      dir_name = Time.now.strftime('%Y%m%d')
      path = "/home/railsuser/backup_db/#{app_name}/#{dir_name}"
      # puts "local_path: #{path}"
      # puts "remote_path: #{remote_path}"
      records = Dir.glob("#{path}/**/*")

      result << {:local_path=> records.last, :remote_path=> remote_path}
    end

    return result
  end
end