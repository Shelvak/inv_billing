# encoding: utf-8

class Frigorifico
  def self.generate
    old_owner = ''
    ['mvfr', 'mvfrch'].each do |fr|
      puts "empieza #{fr}"
      query = 'SELECT  idform, fechapres, codform, tipo_movi, nroins, numero, coddel, anoinv, estadecla '
      query << "FROM #{fr}cab WHERE numero != '0' AND fechapres >= '#{Helpers.two_months_ago}' "
      query << "AND idform NOT IN (#{$last_ids[fr].join(',')}) " if $last_ids[fr].any?
      query << "ORDER BY nroins;"
      Helpers.execute_sql(query).each do |column|

        owner = Helpers.execute_sql(
          "SELECT nombre FROM inscriptos
           WHERE nroins = '#{column['nroins']}'"
        ).first
        owner = owner ? owner['nombre'] : 'desconocido'

        Helpers.create_csv_for(owner, column['nroins'])
        old_owner = owner

        volumen, propierty = 0, ' '

        query = Helpers.execute_sql(
          " SELECT litros, propiedad FROM #{fr}det
            WHERE idform = #{column['idform']}"
        )

        if query && query.first
          propierty = 'Tercero' if query.first['propiedad'].to_i == 2

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

        content_for_csv = [
          column['fechapres'],
          [frigo_type, code_detail[:desc]].join(' '),
          [column['coddel'], column['numero'], column['anoinv']].join('-'),
          "P/ #{volumen} L",
          '$',
          code_detail[:price],
          propierty,
          Helpers.return_status_by_code(column['estadecla'])
        ]

        Helpers.add_to_csv(content_for_csv)
        $new_ids[fr] << column['idform'].to_i
      end
    end
  end
end
