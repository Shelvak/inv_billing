# encoding: utf-8

class Exportation
  def self.generate
    old_owner = ''

    Helpers.execute_sql(
      "SELECT idform, fecpre, paisdest, estdep, numero, coddel, anoinv FROM expcab1
       WHERE numero != '0'
       AND fecpre >= '#{Helpers.two_months_ago}'
       AND idform NOT IN (#{$last_ids['expcab1'].join(',')})
       ORDER BY idform, estdep, paisdest;"
    ).each do |column|


      owner = Helpers.execute_sql(
        "SELECT nombre FROM inscriptos
        WHERE nroins = '#{column['estdep']}'"
      ).first
      owner = owner ? owner['nombre'] : 'desconocido'

      Helpers.create_csv_for(owner, column['estdep'])
      old_owner = owner

      code = column['paisdest']
      country = COUNTRIES[code.to_i]
      country ||= code

      query = Helpers.execute_sql(
        "SELECT rsocial FROM expoterc WHERE idform = #{column['idform'].to_i}"
      )

      owner_propierty = (query && query.count > 0 ? query.first['rsocial'] : '')

      content_for_csv = [
        column['fecpre'],
        'Presenta guía de exportación',
        [column['coddel'], column['numero'], column['anoinv']].join('-'),
        country,
        '$',
        180,
        owner_propierty
      ]

      Helpers.add_to_csv(content_for_csv)
      $new_ids['expcab1'] << column['idform'].to_i
    end
  end
end
