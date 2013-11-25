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

## DB connection
$db_conn = PGconn.connect(
  dbname: 'Bodegas', user: 'postgres', password: 'postgres'
)

## Initializers
Helpers.create_month_dir
$last_ids = {} # { table: [ids] }
Helpers.read_last_record_of_each_table

## Generate the informs
MV02.generate
MV05.generate
Exportation.generate
Frigorifico.generate

## Finalizers ^^
Helpers.save_last_record_of_each_table
Helpers.do_sum_in_all_files
