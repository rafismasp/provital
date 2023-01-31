class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

	mount_uploader :avatar, AvatarUploader

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable,
         # :timeoutable, :timeout_in => 60.minutes, 
         :authentication_keys => [:username]

  belongs_to :company_profile
  belongs_to :department, optional: true
  belongs_to :employee_section, optional: true
  
  validates :username, uniqueness: true

  def active_for_authentication?
	  super && self.status == 'active' # i.e. super && self.is_active
	end

	def inactive_message
	  "Sorry, this account has been deactivated."
	end

  def current_employee_schedule
    "08:00 AM - 17:00 PM"
  end
end
