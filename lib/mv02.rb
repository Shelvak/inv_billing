# encoding: utf-8

class MV02
  def self.generate

    ['mv02', 'mv02ch'].each do |mv|
      old_owner = ''

      Helpers.execute_sql(" SELECT idform, nrorem, nrorec, estadecla,
        lts_rem_t, lts_rem_p, lts_rec_t, lts_rec_p,
        estadocu, numero, coddel, anoinv FROM #{mv}cab
        WHERE numero != '0'
        AND fecinicio >= '2015-04-27'
        AND idform NOT IN (#{$last_ids["#{mv}cab"].join(',')})
        ORDER BY idform, nrorem, nrorec").each do |column|

        owner_type = (column['estadocu'] == 'I') ? 'nrorem' : 'nrorec'
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos
           WHERE nroins = '#{column[owner_type]}'"
        ).first
        owner = owner ? owner['nombre'] : 'desconocido'

        Helpers.create_csv_for(owner, column[owner_type])
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        volumen, propierty = if column['estadocu'] == 'I'
                               [
                                 column['lts_rem_t'].to_i + column['lts_rem_p'].to_i,
                                 (column['lts_rem_t'].to_i == 0 ? '' : 'Tercero')
                               ]
                             else
                               [
                                 column['lts_rec_t'].to_i + column['lts_rec_p'].to_i,
                                 (column['lts_rec_t'].to_i == 0 ? '' : 'Tercero')
                               ]
                             end

        owner_propierty = Helpers.execute_sql(
          " SELECT rsocial FROM #{mv}terc
            WHERE idform = #{column['idform']} "
        )

        if owner_propierty && owner_propierty.count > 0
          propierty = owner_propierty.first['rsocial']
        end

        code_detail = CODIGOS["#{mv}-#{column['estadocu']}"]
        price = if propierty.present? && !code_detail[:third_price].nil?
                  code_detail[:third_price]
                else
                  code_detail[:price]
                end

        content_for_csv = [
          '   ',
          code_detail[:desc],
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          "P/ #{volumen} L",
          '$',
            price,
            propierty,
            Helpers.return_status_by_code(column['estadecla'])
        ]

        Helpers.add_to_csv(content_for_csv)
        $new_ids["#{mv}cab"] << column['idform'].to_i
      end
    end
  end
end
