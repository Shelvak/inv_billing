class MV05
  def self.generate
    old_owner = ''

    $db_conn.exec(
      "SELECT idform, tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
       WHERE idform > #{$last_ids['mv05cab'].to_i}
       and fecpre > '2013-01-01'
       AND numero != '0'
       ORDER BY idform, nroins, tipo_movi"
    ) do |columns|

      columns.each do |column|
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos 
           WHERE nroins = '#{column['nroins']}'"
        ).first['nombre']

        Helpers.create_csv_for(owner)
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        content_for_csv = []
        code = column['tipo_movi']
        code_detail = CODIGOS[code]
        code_detail ||= { desc: 'Desconocido', price: '0' }

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
        $last_ids['mv05cab'] = column['idform']
      end                                                                   
    end
  end
end
