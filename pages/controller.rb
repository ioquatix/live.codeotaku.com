
prepend Actions

class StreamBody < Async::HTTP::Body::Readable
	def initialize(task: Async::Task.current)
		@pipe = IO.pipe
		
		@output = Async::IO::Generic.new(@pipe.first)
		
		puts "Spawning FFmpeg: #{self.command.join(' ')}"
		
		#@pid = Process.spawn("cat", "/dev/urandom", out: @pipe.last, pgroup: true)
		
		@pid = Process.spawn(*self.command, in: '/dev/null', out: @pipe.last, pgroup: true)
		
		@pipe.last.close
	end
	
	def command
		["ffmpeg", "-f", "x11grab", "-framerate", "10", "-i", ENV['DISPLAY'], "-f", "webm", "pipe:1"]
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

on "stream.webm" do
	succeed! body: StreamBody.new, headers: {'content-type' => 'video/webm'}
end
