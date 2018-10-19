
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
			# "-video_size", "1920x1080",
			# "-video_size", "400x300",
			"-framerate", "30",
			"-i", ENV['DISPLAY'],
			"-pix_fmt", "yuv420p",
			"-vf", "scale=1920:-1",
			"-threads", "0",
			*args,
			"-g", "10",
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
			@output.readpartial(1024*1024*32)
		end
	end
end

class WebMStream < VideoStream
	def command
		super(
			"-f", "webm",
			"-c:v", "libvpx-vp9",
			"-speed", "4",
			"-tile-columns", "6",
			"-movflags", "faststart",
			"-b:v", "1M",
		)
	end
end

class MP4Stream < VideoStream
	def command
		super(
			"-f", "mp4",
			"-c:v", "libx264",
			"-x264-params", "keyint=10:scenecut=0",
			"-movflags", "faststart+frag_keyframe+empty_moov",
			"-profile:v", "main",
		)
	end
end

class MOVStream < VideoStream
	def command
		super(
			"-f", "mov",
			"-c:v", "libx264",
			"-x264-params", "keyint=10:scenecut=0",
			"-movflags", "faststart+frag_keyframe+empty_moov",
			"-profile:v", "main",
		)
	end
end

on "stream.webm" do
	succeed! body: WebMStream.new, headers: {'content-type' => 'video/webm'}
end

on "stream.mp4" do |request|
	if range = request.env['HTTP_RANGE']
		pp range
		
		succeed! status: 206, content: "\0\0", headers: {
			'content-type' => 'video/mp4',
			'content-range' => 'bytes 0-1/1000000',
		}
	end
	
	succeed! body: MP4Stream.new, headers: {'content-type' => 'video/mp4'}
end

on "stream.mov" do
	succeed! body: MOVStream.new, headers: {'content-type' => 'video/quicktime'}
end
