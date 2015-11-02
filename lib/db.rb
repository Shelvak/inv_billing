# encoding: ISO8859-1
class DB
  class << self
    def init
      $db_conn = PGconn.connect(
        dbname: 'Bodegas', user: 'postgres', password: 'postgres'
      )

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

        puts "error en bodegas 1"
        p e
        Helpers.log_error(e)
        Helpers.log_error(e.backtrace.join("\n\t"))
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
        "SELECT idform FROM #{table} ORDER BY idform DESC LIMIT 1000;"
      ).map { |r| r['idform'].to_i }
    end

    def insert_ids_in(opts = {})
      table = opts[:table]
      begin
        ids_by_table = $db_bodegas.exec(
          "SELECT idform FROM #{table};"
        ).map { |r| r['idform'].to_s }
      rescue => e
        Helpers.log_error(e)
        ids_by_table = $last_ids[table]
      end

      ids = opts[:ids].map { |id| id unless id.to_i <= 0 || ids_by_table.include?(id) }.compact.uniq.join('),(')

      begin
        if ids != ''
          sql = "INSERT INTO #{table} VALUES (#{ids})"
          Helpers.log_sql(sql)
          $db_bodegas.exec(sql)
        end
      rescue => e
        puts "error en bodegas 2"
        p e
        Helpers.log_error(e)
      end
    end
  end
end
