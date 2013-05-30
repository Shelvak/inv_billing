# encoding: UTF-8

# Gems
require 'pg'
require 'csv'

# Helper-files
require './codes.rb'
require './countries.rb'

# DB connection
@db_conn = PGconn.connect(
  dbname: 'Bodegas', user: 'postgres', password: 'postgres'
)

require './mv05.rb'

MV05.generate(@db_conn)
