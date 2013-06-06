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

      db_conn.exec("SELECT idform, tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
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
            Helpers.log_error e
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

          volumen, propierty = 0, ' '

          begin
            detail = db_conn.exec(
              "SELECT volume, propiedad FROM mv05det
               WHERE disaum = 'A'
               AND idform = #{column['idform']}"
            )

            propierty = 'Tercero' if detail.first['propiedad'].to_i == 2
            detail.each { |d| volumen += d['volume'].to_i }
          rescue => e
            Helpers.log_error e
          end

          if volumen == 0
            begin
              volumen = db_conn.exec(
                "SELECT sum(volume) FROM mv05origfino
                 WHERE idform = #{column['idform']}"
              ).first['count']
            rescue => e
              Helpers.log_error e
            end
          end

          if volumen == 0
            begin
              volumen = db_conn.exec(
                "SELECT sum(volumen) FROM mv05cove103
                 WHERE idform = #{column['idform']}"
              ).first['count']
            rescue => e
              Helpers.log_error e
            end
          end

          if volumen == 0
            begin
              volumen = db_conn.exec(
                "SELECT sum(volumen) FROM mv05terc
                 WHERE disaum = 'A' AND idform = #{column['idform']}"
              ).first['count']
              propierty = 'Tercero'
            rescue => e
              Helpers.log_error e
            end
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
