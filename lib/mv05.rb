# encoding: utf-8

class MV05
  def self.generate

    puts "empieza 05"
    query = 'SELECT idform, fecpre, tipo_movi, nroins, numero, coddel, anoinv, estadecla FROM mv05cab '
    query << "WHERE numero != '0' AND fecpre >= '#{Helpers.two_months_ago}' "
    query << "AND idform NOT IN (#{$last_ids['mv05cab'].join(',')}) " if $last_ids['mv05cab'].any?
    query << 'ORDER BY idform, nroins, tipo_movi;'
    Helpers.execute_sql(query).each do |column|

      owner = Helpers.execute_sql(
        "SELECT nombre FROM inscriptos WHERE nroins='#{column['nroins']}'"
      ).first

      owner = owner ? owner['nombre'] : 'desconocido'
      Helpers.create_csv_for(owner, column['nroins'])

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

      content_for_csv = [
        column['fecpre'],
        [code, code_detail[:desc]].join(' - '),
        [column['coddel'], column['numero'], column['anoinv']].join('-'),
        "P/ #{volumen} L",
        '$',
        code_detail[:price],
        propierty,
        Helpers.return_status_by_code(column['estadecla'])
      ]

      Helpers.add_to_csv(content_for_csv)
      $new_ids['mv05cab'] << column['idform'].to_i
    end
  end
end
