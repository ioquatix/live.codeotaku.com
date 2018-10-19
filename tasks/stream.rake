
namespace :stream do
	task :x11 do
		require 'fileutils'
		
		next_path = File.expand_path("../public/next.jpg", __dir__)
		output_path = File.expand_path("../public/stream.jpg", __dir__)
		
		while true
			system("magick", "import", "-window", "root", next_path)
			FileUtils.mv(next_path, output_path)
			
			sleep(1.0/4.0)
		end
	end
	
	task :darwin do
		require 'async'
		require 'async/http/internet'
		require 'async/http/body/file'
		
		id = ENV['ID']
		password = ENV['PASSWORD']
		
		Async.run do |task|
			internet = Async::HTTP::Internet.new
			output_path = File.expand_path("capture.jpg", __dir__)
			
			while true
				system("screencapture", "-C", "-x", output_path)
				
				response = internet.post("https://live.codeotaku.com/stream/#{id}/upload", {'password' => password}, Async::HTTP::Body::File.open(output_path))
				
				unless response.success?
					abort "Failed to upload: #{response.status}"
				end
				
				response.finish
				
				task.sleep(1.0)
			end
		end
	end
end
