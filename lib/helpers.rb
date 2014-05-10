# encoding: ISO8859-1
class Helpers
  class << self
    def create_csv_for(owner)
      owner_name = delete_innecesary_spaces(owner)

      @@owner_file = if owner_name.match(/trivento/i)
                       month = MONTHS[Date.today.month]
                       "E:/Planillas/Trivento_#{month}.csv"
                     else
                       "#{$month_directory}/#{owner_name}.csv" #.force_encoding('UTF-8')
                     end

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
        contents.each do |c|
          csv << c.map do |e|
            e.is_a?(String) ? e.force_encoding('ISO-8859-1') : e
          end
        end
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

      $month_directory = "E:/Planillas/#{year}/#{month}"
      Helpers.mkdir "E:/Planillas/#{year}"
      Helpers.mkdir $month_directory
    end

    def read_last_record_of_each_table
      CSV.read('last_records.csv').each do |k, v|
        values = v.gsub(/\[|\]/, '').split(',').map(&:to_i)
        values.delete(0)
        $last_ids[k] = values.flatten
      end
    end

    def save_last_record_of_each_table
      CSV.open('last_records.csv', 'w') do |csv|
        $last_ids.each { |key, values| csv << [key, values.map(&:to_i).flatten] }
      end
    end

    def do_sum_in_all_files
      today = Date.today.to_s.split('-').reverse.join('-')
      Dir.glob("#{$month_directory}/*.csv").each do |file|
        total_global = total_propio = total_tercero = 0

        csv_file = CSV.read(file)
        rows_number = csv_file.size - 1

        unless csv_file[rows_number][1].match(/tercero =>/i)

          csv_file.each do |csv|
            total_global += csv[5].to_i

            if csv[6] =~ /\w+/i
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

    def return_status_by_code(status)
      if STATUS_CODES.keys.include?(status)
        STATUS_CODES[status]
      else
        log_error(status)
        'Tipo desconocido'
      end
    end
  end

  private

  def self.delete_innecesary_spaces(string)
    new_string = string[-1] == ' ' ? string.chomp(' ') : string
    new_string[-1] == ' ' ? delete_innecesary_spaces(new_string) : new_string
  end
end
