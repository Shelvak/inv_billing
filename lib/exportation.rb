# encoding: utf-8

class Exportation
  def self.generate(db_conn)
    date_today = Date.today.to_s

    [-3, -2, -1].each do |n|
      date = Date.today.beginning_of_month.advance(months: n)
      year = date.year
      month = MONTHS[date.month]

      month_directory = "../#{year}/#{month}"
      Helpers.mkdir "../#{year}"
      Helpers.mkdir month_directory
  
      tipo = nil

      db_conn.exec("SELECT paisdest, estdep, numero, coddel, anoinv FROM expcab1
                    WHERE fecpre BETWEEN '#{date}' AND '#{date.advance(months: 1, days: -1)}'
                    AND numero != '0'
                    ORDER BY estdep, paisdest") do |columns|

        columns.each do |column|
          begin
            owner = db_conn.exec(
              "SELECT nombre FROM inscriptos 
              WHERE nroins = '#{column['estdep']}'"
            ).first['nombre']

            Helpers.create_csv_for(owner, month_directory)
          rescue => e
            Helpers.log_error e
          end

          content_for_csv = []
          code = column['paisdest']
          country = COUNTRIES[code.to_i]
          country ||= code

          if tipo != code
            content_for_csv << [] 
            content_for_csv << [date_today]
            tipo = code
          end

          content_for_csv << [
            '   ',
            'Presenta guia de exportación',
            [column['coddel'], column['numero'], column['anoinv']].join('-'),
            country,
            '$',
            180
          ]

          Helpers.add_to_csv(content_for_csv)
        end                                                                   
      end
    end
  end
end
