class Frigorifico
  def self.generate
    old_owner = ''
    ['mvfr', 'mvfrch'].each do |fr|
      $db_conn.exec(
        "SELECT 
            idform, codform, tipo_movi, nroins, estadecla, numero, coddel, anoinv 
          FROM #{fr}cab
          WHERE idform > #{$last_ids[fr].to_i}
          AND fechapres >= '2013-06-27'
          AND numero != '0'
          AND estadecla = 'AL'
          ORDER BY nroins"
      ) do |columns|

        columns.each do |column|
          owner = Helpers.execute_sql(
            "SELECT nombre FROM inscriptos 
             WHERE nroins = '#{column['nroins']}'"
          ).first
          owner = owner ? owner['nombre'] : old_owner
        
          Helpers.create_csv_for(owner)
          Helpers.add_date_to_csv if owner != old_owner
          old_owner = owner

          content_for_csv = []
          volumen, propierty = 0, ' '

          query = Helpers.execute_sql(
            " SELECT litros, propiedad FROM #{fr}det
              WHERE idform = #{column['idform']}"
          )

          if query
            if query.try(:first) && query.first['propiedad'].to_i == 2
              propierty = 'Tercero' 
            end

            query.each { |d| volumen += d['litros'].to_i }
          end

          code_detail = CODIGOS["frigo-#{column['tipo_movi']}"]
          frigo_type = case column['codform'].to_i 
                       when 52 then '[Vino]' 
                       when 54 then '[Espumante]'
                       else
                         '----'
                       end

          content_for_csv << [
            '   ',
            [frigo_type, code_detail[:desc]].join(' '),
            [column['coddel'], column['numero'], column['anoinv']].join('-'),
            "P/ #{volumen} L",
            '$',
            code_detail[:price]
          ]

          Helpers.add_to_csv(content_for_csv)
          $last_ids[fr] = column['idform']
        end                                                                   
      end
    end
  end
end
