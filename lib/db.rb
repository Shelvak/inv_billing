# encoding: ISO8859-1
class DB
  class << self
    def init
      tries = 3
      begin
      $db_conn = PGconn.connect(
        dbname: 'Bodegas', user: 'postgres', password: 'postgres'
      )
      rescue => e
        if (tries -= 1) >= 0
          sleep 1
          retry
        end
        Helpers.log_error(e)
      end

      tries = 3

      begin
        $db_bodegas = PGconn.connect(
          host: '192.168.0.200',
          dbname: 'inv_bodegas', user: 'inv_tagger', password: 'inv_tagger')
      rescue => e
        if (tries -= 1) >= 0
          sleep 1
          retry
        end

        p e
        Helpers.log_error(e)
      end

      $last_ids = {}
      $new_ids = {}
    end

    def read_last_ids
      %w(mv02cab mv02chcab mv05cab expcab1 mvfr mvfrch).each do |table|
        $last_ids[table] = all_records_of(table)
        $new_ids[table] = []
      end
    end

    def save_new_ids
      $new_ids.each do |table, ids|
        insert_ids_in(table: table, ids: ids)
      end
    end

    def all_records_of(table)
      $db_bodegas.exec(
        "SELECT idform FROM #{table} WHERE created_at >= '#{Helpers.months_ago(4)}';"
      ).map { |r| r['idform'] }.map(&:to_i).uniq
    end

    def insert_ids_in(opts = {})
      table = opts[:table]
      #begin
      #  ids_by_table = $db_bodegas.exec(
      #    "SELECT idform FROM #{table};"
      #  ).map { |r| r['idform'] }
      #rescue => e
      #  Helpers.log_error(e)
      #  ids_by_table = $last_ids[table]
      #end

      `echo "#{table}:" >> ids`
      `echo "#{$last_ids[table].join(', ')}" >> ids`


      ids = opts[:ids].map(&:to_i).map { |id| id unless id <= 0 }.compact.uniq
      puts "saving #{ids}"

      ids.each do |id|
        begin
            sql = "INSERT INTO #{table} (idform) VALUES (#{id});"
            Helpers.log_sql(sql)
            $db_bodegas.exec(sql)
        rescue => e
          Helpers.log_error(e)
        end
      end
    end
  end
end
