class MV05
  def self.generate
    date_today = Date.today.to_s

    [-3, -2, -1].each do |n|
      date = Date.today.beginning_of_month.advance(months: n)
      year = date.year
      month = MONTHS[date.month]
  
      month_directory = "../#{year}/#{month}"
      Helpers.mkdir "../#{year}"
      Helpers.mkdir month_directory

      tipo = nil

      $db_conn.exec("SELECT idform, tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
                    WHERE fecpre BETWEEN '#{date}' AND '#{date.advance(months: 1, days: -1)}'
                    AND numero != '0'
                    ORDER BY nroins, tipo_movi") do |columns|


        columns.each do |column|
          query = Helpers.execute_sql(
            "SELECT nombre FROM inscriptos 
             WHERE nroins = '#{column['nroins']}'"
          )
          Helpers.create_csv_for(query.first['nombre'], month_directory) if query

          content_for_csv = []
          code = column['tipo_movi']
          code_detail = CODIGOS[code]
          code_detail ||= { desc: 'Desconocido', price: '0' }

          if tipo != code
            content_for_csv << [] 
            content_for_csv << [date_today]
            tipo = code
          end

          volumen, propierty = 0, ' '

          query = Helpers.execute_sql(
            " SELECT volume, propiedad FROM mv05det
              WHERE disaum = 'A' AND idform = #{column['idform']}"
          )

          if query
            if query.try(:first) && query.first['propiedad'].to_i == 2
              propierty = 'Tercero' 
            end

            query.each { |d| volumen += d['volume'].to_i }
          end

          if volumen == 0
            query = Helpers.execute_sql(
                "SELECT sum(volume) FROM mv05origfino
                 WHERE idform = #{column['idform']}"
            )

            volumen = query.first['count'] if query
          end

          if volumen == 0
            query = Helpers.execute_sql(
                "SELECT sum(volumen) FROM mv05cove103
                 WHERE idform = #{column['idform']}"
            )

            volumen = query.first['count'] if query
          end

          if volumen == 0
            query = Helpers.execute_sql(
              "SELECT sum(volumen) FROM mv05terc
               WHERE disaum = 'A' AND idform = #{column['idform']}"
            )
  
            volumen = query.first['count'] if query
            propierty = 'Tercero'
          end

          content_for_csv << [
            '   ',
            [code, code_detail[:desc]].join(' - '),
            [column['coddel'], column['numero'], column['anoinv']].join('-'),
            "P/ #{volumen} L",
            '$',
            code_detail[:price],
            propierty
          ]

          Helpers.add_to_csv(content_for_csv)
        end                                                                   
      end
    end
  end
end
