
require 'relaxo/model'
require 'relaxo/model/properties/bcrypt'

module Live
	class Stream
		include Relaxo::Model
		
		property :id, UUID
		property :password, Optional[Attribute[BCrypt::Password]]
		
		property :created_at, Attribute[DateTime]
		property :updated_at, Attribute[DateTime]
		
		view :all, :type, index: [:id]
		
		def authorize(password)
			self.password == password
		end
		
		def stream_root
			File.expand_path("../../public/stream", __dir__)
		end
		
		def next_path
			File.join(stream_root, self.id, "next.jpeg")
		end
		
		def latest_path
			File.join(stream_root, self.id, "latest.jpeg")
		end
	end
end
