require 'active_support/core_ext/date/calculations.rb'
require './i18n.rb'

class MV05

  def self.generate(db_conn)

    [-3, -2, -1].each do |n|
      date = Date.today.beginning_of_month.advance(months: n)
      year = date.year
      month = @@MONTHS[date.month]
  
      begin
        Dir.mkdir year.to_s
      rescue
        puts 'Ya existe'
      end

      begin
        Dir.mkdir "#{year}/#{month}"
      rescue
        puts 'Ya existe'
      end

      month_directory = [year, month].join('/')
      nro_inscripto = ' '
      owner_directory = nil
      tipo = nil

      db_conn.exec("SELECT tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
                    WHERE fecpre BETWEEN '#{date}' AND '#{date.advance(months: 1, days: -1)}'
                    AND numero != '0'
                    ORDER BY nroins, tipo_movi") do |columns|


        columns.each do |column|
          begin
            if nro_inscripto != column['nroins']
              owner = db_conn.exec(
                "SELECT nombre FROM inscriptos WHERE nroins = '#{column['nroins']}'"
              ).first['nombre'].to_s

              owner_name = delete_innecesary_spaces(owner)
              owner_directory = [month_directory, owner_name].join('/')
              Dir.mkdir owner_directory

              CSV.open("#{owner_directory}/mv05.csv", 'ab') do |csv|
                3.times { csv << [] }
                csv << [ '  ', "Tramites para #{owner_name.upcase}" ]
                2.times { csv << [] }
              end
            end

            nro_inscripto = column['nroins']
          rescue
            puts 'No se pudo conseguir el inscripto'
          end

          CSV.open("#{owner_directory}/mv05.csv", 'ab') do |csv|
            code = column['tipo_movi']
            code_detail = CODIGOS[code]
            code_detail ||= { desc: 'Desconocido', price: '0' }

            csv << [] if tipo != code
            tipo = code

            volumen = begin
              db_conn.exec(
                "SELECT volume FROM mv05origfino WHERE nro_doc = #{column['numero']}"
              ).first
            rescue
              puts 'Sin volumen'
            end

            csv << [
              '   ',
              [code, code_detail[:desc]].join(' - '),
              [column['coddel'], column['numero'], column['anoinv']].join('-'),
              (volumen ? "P/ #{volumen['volume']} L" : ''),
              '$',
              code_detail[:price]
            ]
          end                                                                   
        end                                                                   
      end
    end
  end

  def self.delete_innecesary_spaces(string)
    new_string = string[-1] == ' ' ? string.chomp(' ') : string
    new_string[-1] == ' ' ? delete_innecesary_spaces(new_string) : new_string
  end
end
