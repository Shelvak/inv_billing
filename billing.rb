# encoding: UTF-8

# Gems
require 'pg'
require 'csv'

# Helper-files
require './codes.rb'

# DB connection
bodegas = PGconn.connect(
  dbname: 'Bodegas', user: 'postgres', password: 'postgres'
)

CSV.open('rock.csv', 'w') do |csv|
  # Put some spaces =)
  3.times { csv << [] }
  tipo = ''

	bodegas.exec("SELECT * FROM mv05cab WHERE fecpre = '2013-03-27' 
                  ORDER BY tipo_movi") do |columns|
    begin
      nro_inscripto = columns.first['nroins']
      owner = bodegas.exec(
        "SELECT nombre FROM inscriptos WHERE nroins = '#{nro_inscripto}'"
      ).first

      csv << [ '  ', "Tramites para #{owner['nombre'].upcase}" ]

      2.times { csv << [] }
    rescue
      puts 'ROCK'
    end

    columns.each do |column|
      cod = column['tipo_movi']
      csv << [] if tipo != cod
      tipo = cod

      volumen = begin
        bodegas.exec(
          "SELECT volume FROM mv05origfino WHERE nro_doc = #{column['numero']}"
        ).first
      rescue
        puts 'rock'
      end

      vol = (volumen ? "P/ #{volumen['volume']} L" : '')
      cod_detail = CODIGOS[cod]
      cod_description = [cod, cod_detail[:desc]].join(' - ')
      nro_pedido = [column['coddel'], column['numero'], column['anoinv']].join('-')
      precio = cod_detail[:price]

      csv << [
        '   ',
        cod_description,
        nro_pedido,
        vol,
        '$',
        precio
      ]
    end                                                                   
	end
end
