
DATABASE_ENV = (ENV['DATABASE_ENV'] || RACK_ENV || :development).to_s

require 'relaxo'

DATABASE_PATH = File.join(__dir__, DATABASE_ENV)

module Live
	# Configure the database connection:
	DB = Relaxo.connect(DATABASE_PATH, logger: Logger.new($stderr))
end

require 'live'
