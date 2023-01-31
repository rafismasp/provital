class UserMailer < ActionMailer::Base
	# default from: "cronjob@tik.tri-saudara.co.id"
	default from: "noreply@provitalperdana.com"

	def tiki(emailto, emailsubject, emailcontent, emailattachment)
		
		if emailattachment.present?
		filename_original = emailattachment
		path    = "#{Rails.root}/tmp/export/#{filename_original}"
		attachments[filename_original] = {mime_type: 'application/mymimetype',
										content: File.read(path)} 
	  end 
	@emailto=emailto
		@emailcontent= emailcontent
		mail(to: @emailto, subject: emailsubject, body: @emailcontent)  do |format|
      format.html { render '/user_mailer/dentemplate' }
    end
		# mail(to: @emailto, subject: emailsubject, body: emailcontent, content_type: 'text/plain')
		#mail(to: @emailto, subject: emailsubject, body: emailcontent, content_type: 'multipart/mixed')
		puts "delivered"
	end 

end
