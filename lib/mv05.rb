# encoding: utf-8

class MV05
  def self.generate
    old_owner = ''

    $db_conn.exec(
      "SELECT idform, tipo_movi, nroins, numero, coddel, anoinv FROM mv05cab 
       WHERE idform > #{$last_ids['mv05cab'].to_i}
       AND fecpre >= '2013-06-27'
       AND numero != '0'
       ORDER BY idform, nroins, tipo_movi"
    ) do |columns|

      columns.each do |column|
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos 
           WHERE nroins = '#{column['nroins']}'"
        ).first

        owner = owner ? owner['nombre'] : 'desconocido'

        Helpers.create_csv_for(owner)
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        content_for_csv = []
        code = column['tipo_movi']
        code_detail = CODIGOS[code]
        code_detail ||= { desc: 'Desconocido', price: '0' }

        volumen, propierty = 0, ' '

        ['A', 'D'].each do |a_d|
          query = Helpers.execute_sql(
            " SELECT volume, propiedad FROM mv05det
              WHERE disaum = '#{a_d}' AND idform = #{column['idform']}"
          )

          if query && volumen == 0
            if query.try(:first) && query.first['propiedad'].to_i == 2
              propierty = 'Tercero' 
            end

            query.each { |d| volumen += d['volume'].to_i }
          end
        end

        ['origfino', 'cove103'].each do |x|
          if volumen == 0
            query = Helpers.execute_sql(
                "SELECT sum(volume) FROM mv05#{x}
                 WHERE idform = #{column['idform']}"
            )

            volumen = query.first['count'] if query
          end
        end

        ['A', 'D'].each do |a_d|
          if volumen == 0
            query = Helpers.execute_sql(
              "SELECT sum(volumen) FROM mv05terc
               WHERE disaum = '#{a_d}' AND idform = #{column['idform']}"
            )

            volumen = query.first['count'] if query
            propierty = 'Tercero'
          end
        end

        owner_propierty = Helpers.execute_sql(
          " SELECT rsocial FROM mv05terc 
            WHERE idform = #{column['idform']} "
        )

        if owner_propierty && owner_propierty.count > 0
          propierty = owner_propierty.first['rsocial']
        end

        status = column['estadecla'] == 'AL' ? column['estadecla'] : ''

        content_for_csv << [
          '   ',
          [code, code_detail[:desc]].join(' - '),
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          "P/ #{volumen} L",
          '$',
          code_detail[:price],
          propierty,
          status
        ]

        Helpers.add_to_csv(content_for_csv)
        $last_ids['mv05cab'] = column['idform']
      end                                                                   
    end
  end
end
