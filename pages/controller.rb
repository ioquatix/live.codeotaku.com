
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
			"-vf", "scale=1920:-1",
			# "-threads", "4",
			*args,
			"-b:v", "1M",
			# "-bufsize", "4000K",
			# "-g", "10",
			"-preset", "ultrafast",
			"pipe:1",
		]
	end
	
	def close(error = nil)
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
		)
	end
end

class MP4Stream < VideoStream
	def command
		super(
			"-f", "mp4",
			"-c:v", "libx264",
			"-movflags", "faststart+frag_keyframe+empty_moov",
			# "-profile:v", "main",
			"-profile:v", "baseline",
			"-level", "3.0",
		)
	end
end

on "stream.webm" do
	succeed! body: WebMStream.new, headers: {'content-type' => 'video/webm', 'cache-control' => 'no-cache'}
end

on "stream.mp4" do
	succeed! body: MP4Stream.new, headers: {'content-type' => 'video/mp4', 'cache-control' => 'no-cache'}
end
