# encoding: ISO8859-1
class DB

  def self.init
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
      Bugsnag.notify(e)
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
      Bugsnag.notify(e)
      Helpers.log_error(e)
    end

    $last_ids = {}
    $new_ids = {}
  end

  def self.read_last_ids
    %w(mv02cab mv02chcab mv05cab expcab1 mvfr mvfrch).each do |table|
      $last_ids[table] = all_records_of(table)
      $new_ids[table] = []
    end
  end

  def self.save_new_ids
    $new_ids.each do |table, ids|
      insert_ids_in(table: table, ids: ids)
    end
  end

  def self.all_records_of(table)
    $db_bodegas.exec(
      "SELECT idform FROM #{table} WHERE created_at >= '#{Helpers.months_ago(2)}';"
    ).map { |r| r['idform'] }.map(&:to_i).uniq
  end

  def self.insert_ids_in(opts = {})
    table = opts[:table]

    Helpers.log('ids', table)
    Helpers.log('ids', $last_ids[table].join(', '))

    opts[:ids].map(&:to_i).map { |id| id unless id <= 0 }.compact.uniq.each do |id|
      begin
        select = "SELECT idform FROM #{table} WHERE idform=#{id};"
        Helpers.log_sql(select)
        if $db_bodegas.exec(select).first
          update = "UPDATE #{table} SET created_at='#{Time.now.to_s}' WHERE idform=#{id};"
          Helpers.log_sql(update)
          $db_bodegas.exec(update)
        else
          insert = "INSERT INTO #{table} (idform) VALUES (#{id});"
          Helpers.log_sql(insert)
          $db_bodegas.exec(insert)
        end
      rescue => e
        Bugsnag.notify(e)
        Helpers.log_error(e)
      end
    end
  end
end
