# encoding: ISO8859-1
class DB
  class << self
    def init
      $db_conn = PGconn.connect(
        dbname: 'Bodegas', user: 'postgres', password: 'postgres'
      )

      $db_bodegas = PGconn.connect(
        host: '192.168.0.200',
        dbname: 'inv_bodegas',
        user: 'inv_tagger',
        password: 'inv_tagger'
      )

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
        "SELECT DISTINCT(idform) FROM #{table}"
      ).map { |r| r['idform'] }
    end

    def insert_ids_in(opts = {})
      table = opts[:table]
      ids = opts[:ids].delete_if { |id| id.to_i <= 0 }.join('),(')

      $db_bodegas.exec "INSERT INTO #{table} VALUES (#{ids})"
    end

    def insert_olds
      CSV.read('last_records.csv').each do |k, v|
        values = v.gsub(/\[|\]/, '').split(',').map(&:to_i)
        values.delete(0)

        insert_ids_in(table: k, values.flatten.uniq.compact)
      end
    end
  end
end
