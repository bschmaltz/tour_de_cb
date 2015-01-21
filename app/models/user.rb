class User < ActiveRecord::Base
	has_secure_password
	validates_uniqueness_of :email, case_sensitive: false
	validates :email, presence: true, uniqueness: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
end
