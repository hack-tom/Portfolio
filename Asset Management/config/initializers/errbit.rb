Airbrake.configure do |config|
  config.api_key = '1c3ec00117bc1f4f2baca6fb8ca9af02'
  config.host    = 'errbit.hut.shefcompsci.org.uk'
  config.port    = 443
  config.secure  = config.port == 443
end