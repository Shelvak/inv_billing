# encoding: UTF-8

## Stdlib
require 'csv'
require 'fileutils'

## Gems
require 'pg'

## Helper-files
Dir.glob('./lib/*.rb').each do |name|
  require name
end

## Rails helpers =D
require 'active_support/core_ext/date/calculations.rb'

## Logging good exceptions
require 'bugsnag'
Bugsnag.configure do |config|
  config.api_key = '3b712854ca14c2360dec198db7017962'
  config.use_ssl = false
end

begin
  ## Initializers
  DB.init
  return unless $db_conn && $db_bodegas

  Helpers.create_month_dir
  DB.read_last_ids

  puts "Ids: #{$last_ids.map {|k, v| {k => v.size}}.join(', ')}"

  ## Generate the informs
  MV02.generate
  MV05.generate
  Exportation.generate
  Frigorifico.generate

  puts "New Ids: #{$new_ids.map {|k, v| {k => v.size}}.join(', ')}"

  ## Finalizers ^^
  DB.save_new_ids
  Helpers.do_sum_in_all_files
rescue => e
  Bugsnag.notify(e)
  Helpers.log_error(e)
  Helpers.log_error(e.backtrace.join("\n\t"))
end
