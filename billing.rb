# encoding: UTF-8

# Gems
require 'pg'
require 'csv'

# Helper-files
require './codes.rb'
require './countries.rb'
require './traductions.rb'

# Rails helpers =D
require 'active_support/core_ext/date/calculations.rb'

# DB connection
db_conn = PGconn.connect(
  dbname: 'Bodegas', user: 'postgres', password: 'postgres'
)

# Generation classes 
require './mv05.rb'
require './exportation.rb'

MV05.generate(db_conn)
Exportation.generate(db_conn)
