class Lobby < ActiveRecord::Base
	validates_uniqueness_of :name, case_sensitive: false
end
