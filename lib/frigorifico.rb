# encoding: utf-8

class Frigorifico
  def self.generate
    old_owner = ''
    ['mvfr', 'mvfrch'].each do |fr|
      $db_conn.exec(
        "SELECT  idform, codform, tipo_movi, nroins, numero, coddel, anoinv, estadecla
          FROM #{fr}cab
          WHERE idform > #{$last_ids[fr].to_i}
          AND fechapres >= '2013-08-27'
          AND numero != '0'
          ORDER BY nroins"
      ) do |columns|

        columns.each do |column|
          $last_ids[fr] = column['idform']

          owner = Helpers.execute_sql(
            "SELECT nombre FROM inscriptos 
             WHERE nroins = '#{column['nroins']}'"
          ).first
          owner = owner ? owner['nombre'] : 'desconocido'
        
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

          owner_propierty = Helpers.execute_sql(
            " SELECT rsocial FROM mvfrigterc 
              WHERE idform = #{column['idform']} "
          )

          if owner_propierty && owner_propierty.count > 0
            propierty = owner_propierty.first['rsocial']
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
            code_detail[:price],
            propierty,
            Helpers.return_status_by_code(column['estadecla'])
          ]

          Helpers.add_to_csv(content_for_csv)
        end                                                                   
      end
    end
  end
end
