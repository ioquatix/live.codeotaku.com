
prepend Actions

on 'index' do
	@streams = Live::Stream.all(Live::DB.current)
end
