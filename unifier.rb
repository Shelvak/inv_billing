require 'csv'

Dir['viejas/*.csv'].each do |file|
  begin
    bad_file = CSV.open(file, 'r:ISO-8859-1').read
  rescue => e
    puts file
    puts e
  end

  uniq_records = bad_file.uniq

  uniq_records.each {|e| ap e if e.join.match(/1093279/) }

  total_global = 0
  total_propio = 0
  total_tercero = 0

  uniq_records.each do |csv|
    amount = csv[5].to_i
    total_global += amount

    if csv[6].to_s.strip =~ /\w+/i
      total_tercero += amount
    else
      total_propio += amount
    end
  end

  new_name = "nuevas/#{File.basename(file)}"

  CSV.open(new_name, 'w:ISO-8858-1') do |csv|
    uniq_records.each { |row| csv << row }
    csv << []
    csv << [nil, "Total => $ #{total_global}"]
    csv << [nil, "Propio => $ #{total_propio}"]
    csv << [nil, "Tercero => $ #{total_tercero}"]
  end
end

db = PGconn.new dbname: 'inv_bodegas', user: 'inv_tagger', password: 'inv_tagger'

%w(mv02cab mv02chcab mv05cab expcab1 mvfr mvfrch).each do |table|
  puts "Starting with #{table}"
  query = db.exec("SELECT * FROM #{table};")
  array = query.to_a.map {|e| e['idform']};nil

  ruby_uniq = array.uniq.size
  if ruby_uniq == query.count
    puts "#{table} already clean"
    next
  end
  grouped = {}

  array.uniq.each do |e|
    grouped[e] = array.count(e) if (array.count(e) > 1)
  end;nil

  grouped.each do |idform, count|
    db.exec("delete from #{table} where idform=#{idform};")
    db.exec("insert into #{table} (idform) VALUES (#{idform});")
  end;nil

  cleaned_count = 0 - grouped.size
  grouped.each {|k, v| cleaned_count += v.to_i};nil
  puts "#{table} #{cleaned_count} values cleaned"
end
