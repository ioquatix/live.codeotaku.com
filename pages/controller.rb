
prepend Actions

class VideoStream < Async::HTTP::Body::Readable
	def initialize(task: Async::Task.current)
		@pipe = IO.pipe
		
		@output = Async::IO::Generic.new(@pipe.first)
		
		puts "Spawning FFmpeg: #{self.command.join(' ')}"
		
		@pid = Process.spawn(*self.command, in: '/dev/null', out: @pipe.last, pgroup: true)
		
		@pipe.last.close
	end
	
	def command(*args)
		[
			"ffmpeg",
			"-f", "x11grab",
			"-video_size", "3840x2160",
			"-framerate", "10",
			"-i", ENV['DISPLAY'],
			"-pix_fmt", "yuv420p",
			"-vf", "scale=1200:-1",
			*args,
			"-preset", "ultrafast",
			"pipe:1",
		]
	end
	
	def close(error = nil)
		$stderr.puts "killing @pid..."
		Process.kill(:KILL, -@pid)
		
		@output.close
		@output = nil
		
		super
	end
	
	def read
		if @output
			@output.readpartial(1024*1024)
		end
	end
end

class WebMStream < VideoStream
	def command
		super(
			"-f", "webm",
			"-c:v", "libvpx-vp9",
			"-b:v", "256K",
			"-speed", "4",
		)
	end
end

class MP4Stream < VideoStream
	def command
		super(
			"-f", "mp4",
			"-b:v", "256K",
		)
	end
end

on "stream.webm" do
	succeed! body: WebMStream.new, headers: {'content-type' => 'video/webm'}
end

on "stream.mp4" do
	succeed! body: MP4Stream.new, headers: {'content-type' => 'video/mp4'}
end
