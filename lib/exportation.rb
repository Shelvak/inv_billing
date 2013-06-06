# encoding: utf-8

class Exportation
  def self.generate
    old_owner = ''

    $db_conn.exec(
      "SELECT idform, paisdest, estdep, numero, coddel, anoinv FROM expcab1
       WHERE idform > #{$last_ids['expcab1'].to_i}
       AND fecpre > '2013-01-01'
       AND numero != '0'
       ORDER BY idform, estdep, paisdest"
    ) do |columns|

      columns.each do |column|
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos 
          WHERE nroins = '#{column['estdep']}'"
        ).first['nombre']

        Helpers.create_csv_for(owner)
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        content_for_csv = []
        code = column['paisdest']
        country = COUNTRIES[code.to_i]
        country ||= code

        content_for_csv << [
          '   ',
          'Presenta guía de exportación',
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          country,
          '$',
          180
        ]

        Helpers.add_to_csv(content_for_csv)
        $last_ids['expcab1'] = column['idform']
      end                                                                   
    end
  end
end
