class MV02
  def self.generate
    old_owner = ''

    $db_conn.exec(
      " SELECT idform, nrorem, nrorec, 
        lts_rem_t, lts_rem_p, lts_rec_t, lts_rec_p,
        estadocu, numero, coddel, anoinv FROM mv02cab 
        WHERE idform > #{$last_ids['mv02cab'].to_i}
        AND fecinicio >= '2013-06-27'
        AND numero != '0'
        AND estadecla = 'AL'
        ORDER BY idform, nrorem, nrorec"
    ) do |columns|

      columns.each do |column|
        owner_type = (column['estadocu'] == 'I') ? 'nrorem' : 'nrorec'
        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos 
           WHERE nroins = '#{column[owner_type]}'"
        ).first
        owner = owner ? owner['nombre'] : 'desconocido'

        Helpers.create_csv_for(owner)
        Helpers.add_date_to_csv if owner != old_owner
        old_owner = owner

        content_for_csv = []
        volumen, prop = if column['estadocu'] == 'I'
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

        code_detail = CODIGOS["MV02-#{column['estadocu']}"]

        content_for_csv << [
          '   ',
          code_detail[:desc],
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          "P/ #{volumen} L",
          '$',
          code_detail[:price],
          prop
        ]

        Helpers.add_to_csv(content_for_csv)
        $last_ids['mv02cab'] = column['idform']
      end                                                                   
    end
  end
end
