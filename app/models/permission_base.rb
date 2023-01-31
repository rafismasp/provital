class PermissionBase < ApplicationRecord
	has_many :user_permissions
end
