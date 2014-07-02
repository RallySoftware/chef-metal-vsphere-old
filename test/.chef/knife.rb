local_mode true
config_dir "#{File.expand_path('..', File.dirname(__FILE__))}/"

ENV['VMONKEY_YML'] ||= File.expand_path(File.join(File.dirname(__FILE__), '.vmonkey'))
