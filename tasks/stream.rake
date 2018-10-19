
namespace :stream do
	task :local do
		require 'fileutils'
		
		next_path = File.expand_path("../public/next.jpg", __dir__)
		output_path = File.expand_path("../public/stream.jpg", __dir__)
		
		while true
			system("magick", "import", "-window", "root", next_path)
			FileUtils.mv(next_path, output_path)
			
			sleep(1.0/4.0)
		end
	end
end
