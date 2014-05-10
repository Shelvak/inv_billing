# encoding: utf-8

class Exportation
  def self.generate
    old_owner = ''

    $db_conn.exec(
      "SELECT idform, paisdest, estdep, numero, coddel, anoinv FROM expcab1
       WHERE idform NOT IN (#{$last_ids['expcab1'].join(',')})
       AND fecpre >= '2014-04-27'
       AND numero != '0'
       ORDER BY idform, estdep, paisdest"
    ) do |columns|

      columns.each do |column|
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos
          WHERE nroins = '#{column['estdep']}'"
        ).first
        owner = owner ? owner['nombre'] : 'desconocido'

        Helpers.create_csv_for(owner)
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        content_for_csv = []
        code = column['paisdest']
        country = COUNTRIES[code.to_i]
        country ||= code

        query = Helpers.execute_sql(
          "SELECT rsocial FROM expoterc WHERE idform = #{column['idform'].to_i}"
        )

        owner_propierty = (query && query.count > 0 ? query.first['rsocial'] : '')

        content_for_csv << [
          '   ',
          'Presenta guía de exportación',
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          country,
          '$',
          180,
          owner_propierty
        ]

        Helpers.add_to_csv(content_for_csv)
        $last_ids['expcab1'] ||= []
        $last_ids['expcab1'] << column['idform']
      end
    end
  end
end
