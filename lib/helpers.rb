class Helpers
  class << self
    def create_csv_for(owner)
      owner_name = delete_innecesary_spaces(owner)
      @@owner_file = "#{$month_directory}/#{owner_name}.csv"
                
      unless File.exists? @@owner_file
        CSV.open(@@owner_file, 'ab') do |csv|
          3.times { csv << [] }
          csv << [ '  ', "Tramites para #{owner_name.upcase}" ]
          2.times { csv << [] }
        end
      end
    end

    def add_to_csv(contents)
      CSV.open(@@owner_file, 'ab') do |csv|
        contents.each { |c| csv << c }
      end
    end

    def add_date_to_csv
      CSV.open(@@owner_file, 'ab') do |csv|
        csv << [Date.today.to_s.split('-').reverse.join('-')]
      end
    end

    def mkdir(dir)
      begin
        Dir.mkdir dir
      rescue => e
        log_error e
      end
    end

    def log_error(error)
      %x{echo "#{error}" >> errores}
    end

    def execute_sql(query)
      begin
        $db_conn.exec(query)
      rescue => e
        log_error e
      end
    end

    def create_month_dir
      date = Date.today

      if date.day >= 27
        next_month = date.next_month
        year = next_month.year
        month = [next_month.month, MONTHS[next_month.month]].join(' ')
      else
        year = date.year
        month = [date.month, MONTHS[date.month]].join(' ')
      end

      $month_directory = "F:/Planillas/#{year}/#{month}"
      Helpers.mkdir "F:/Planillas/#{year}"
      Helpers.mkdir $month_directory
    end

    def read_last_record_of_each_table
      CSV.read('last_records.csv').each { |key, value| $last_ids[key] = value }
    end

    def save_last_record_of_each_table
      CSV.open('last_records.csv', 'w') do |csv|
        $last_ids.each { |key, value| csv << [key, value] }
      end
    end

    def do_sum_in_all_files
      today = Date.today.to_s.split('-').reverse.join('-')
      Dir.glob("#{$month_directory}/*.csv").each do |file|
        total_global = total_propio = total_tercero = 0

        CSV.read(file).each do |csv| 
          total_global += csv[5].to_i

          if csv[6] =~ /tercero/i
            total_tercero += csv[5].to_i
          else
            total_propio += csv[5].to_i 
          end
        end

        totals = [total_global, total_propio, total_tercero].join('/')

        CSV.open(file, 'ab') do |csv| 
          csv << []
          csv << [today, "Total => $ #{total_global}"]
          csv << [today, "Propio => $ #{total_propio}"]
          csv << [today, "Tercero => $ #{total_tercero}"]
        end
      end
    end
  end

  private

  def self.delete_innecesary_spaces(string)
    new_string = string[-1] == ' ' ? string.chomp(' ') : string
    new_string[-1] == ' ' ? delete_innecesary_spaces(new_string) : new_string
  end
end
