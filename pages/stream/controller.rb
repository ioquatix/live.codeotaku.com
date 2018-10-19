
prepend Rewrite, Actions

rewrite.extract_prefix id: /[a-z0-9-]{36}/ do |request, path, match|
	fail! unless @stream = Live::Stream.fetch_all(Live::DB.current, id: @id)
end

on 'upload' do |request|
	fail! :unauthorized unless @stream.authorize(request.env['HTTP_PASSWORD'])
	
	if body = request.body
		next_path = @stream.next_path
		
		begin
			FileUtils.mkdir_p(File.dirname(next_path))
			
			File.open(next_path, File::WRONLY|File::CREAT|File::EXCL) do |file|
				body.each do |chunk|
					file.write(chunk)
				end
				
				FileUtils.mv(next_path, @stream.latest_path)
			end
		ensure
			FileUtils.rm_f(next_path)
		end
		
		succeed!
	end
end
