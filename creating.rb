# encoding: UTF-8

## Gems
require 'pg'
require 'csv'

## Helper-files
Dir.glob('./lib/*.rb').each do |name|
  require name
end

## Rails helpers =D
require 'active_support/core_ext/date/calculations.rb'


begin
  ## Initializers
  DB.init
  p $db_bodegas
  DB.insert_olds
rescue => e
  Helpers.log_error(e)
  Helpers.log_error(e.backtrace.join("\n\t"))
end
