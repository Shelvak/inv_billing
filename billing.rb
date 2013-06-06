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

# Generate the informs
MV05.generate
Exportation.generate
