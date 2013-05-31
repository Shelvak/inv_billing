# encoding: utf-8

class Exportation
  def self.generate(db_conn)
    date_today = Date.today.to_s

    [-3, -2, -1].each do |n|
      date = Date.today.beginning_of_month.advance(months: n)
      year = date.year
      month = MONTHS[date.month]

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
      tipo = ''

      db_conn.exec("SELECT paisdest, estdep, numero, coddel, anoinv FROM expcab1
                    WHERE fecpre BETWEEN '#{date}' AND '#{date.advance(months: 1, days: -1)}'
                    AND numero != '0'
                    ORDER BY estdep, paisdest") do |columns|

        columns.each do |column|
          begin
            if nro_inscripto != column['estdep']
              nro_inscripto = column['estdep']
              owner = db_conn.exec(
                "SELECT nombre FROM inscriptos WHERE nroins = '#{column['estdep']}'"
              ).first['nombre'].to_s

              owner_name = delete_innecesary_spaces(owner)
              owner_directory = [month_directory, owner_name].join('/')
              owner_directory
              Dir.mkdir owner_directory

              CSV.open("#{owner_directory}/exportacion.csv", 'ab') do |csv|
                3.times { csv << [] }
                csv << [ '  ', "Tramites para #{owner_name.upcase}" ]
                2.times { csv << [] }
              end
            end
          rescue
            puts 'No se pudo conseguir el inscripto'
          end

          CSV.open("#{owner_directory}/exportacion.csv", 'ab') do |csv|
            code = column['paisdest']
            country = COUNTRIES[code.to_i]
            country ||= code

            if tipo != code
              csv << [] 
              csv << [date_today]
              tipo = code
            end

            csv << [
              '   ',
              'Presenta guia de exportación',
              [column['coddel'], column['numero'], column['anoinv']].join('-'),
              country,
              '$',
              180
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
