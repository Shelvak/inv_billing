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
  Helpers.log_error(e)
  Helpers.log_error(e.backtrace.join("\n\t"))
end
