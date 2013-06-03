class MV05
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

      db_conn.exec("SELECT tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
                    WHERE fecpre BETWEEN '#{date}' AND '#{date.advance(months: 1, days: -1)}'
                    AND numero != '0'
                    ORDER BY nroins, tipo_movi") do |columns|


        columns.each do |column|
          begin
            owner = db_conn.exec(
              "SELECT nombre FROM inscriptos 
               WHERE nroins = '#{column['nroins']}'"
            ).first['nombre']

            Helpers.create_csv_for(owner, month_directory)
          rescue => e
            puts e
            Helpers.log_error(e)
          end

          content_for_csv = []
          code = column['tipo_movi']
          code_detail = CODIGOS[code]
          code_detail ||= { desc: 'Desconocido', price: '0' }

          if tipo != code
            content_for_csv << [] 
            content_for_csv << [date_today]
            tipo = code
          end

          volumen = begin
            db_conn.exec(
              "SELECT volume FROM mv05origfino 
               WHERE nro_doc = #{column['numero']}"
            ).first
          rescue Exception => e
            puts e
          end

          content_for_csv << [
            '   ',
            [code, code_detail[:desc]].join(' - '),
            [column['coddel'], column['numero'], column['anoinv']].join('-'),
            (volumen ? "P/ #{volumen['volume']} L" : ''),
            '$',
            code_detail[:price]
          ]

          Helpers.add_to_csv(content_for_csv)
        end                                                                   
      end
    end
  end
end
