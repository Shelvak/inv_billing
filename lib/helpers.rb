# encoding: ISO8859-1
class Helpers
  class << self
    def create_csv_for(owner, nroins = '')
      owner_name = delete_innecesary_spaces(owner)

      @@owner_file = if owner_name.match(/trivento/i)
                       month = MONTHS[today.month]
                       "E:/Planillas/Trivento_#{nroins}_#{month}.csv"
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

    def add_to_csv(content)
      CSV.open(@@owner_file, 'ab') do |csv|
        csv << content.map do |e|
          e.is_a?(String) ? delete_innecesary_spaces(e.force_encoding('ISO-8859-1')) : e
        end
      end
    end

    def mkdir(dir)
      begin
        FileUtils.mkdir_p dir
      rescue => e
        Bugsnag.notify(e)
        log_error e
      end
    end

    def log_error(error)
      log('errores', error)
    end

    def log_sql(sql)
      log('sql', sql)
    end

    def log(name, msg)
      file_name = "#{name}_#{Date.today.strftime('%m-%Y')}.txt"
      File.open(file_name, 'a') do |f|
        f.write("[#{now_to_s}]  #{msg}\n")
      end
    end

    def execute_sql(query)
      begin
        log_sql(query)
        $db_conn.exec(query)
      rescue => e
        Bugsnag.notify(e)
        log_error e
        []
      end
    end

    def create_month_dir
      if today.day >= 27
        next_month = today.next_month
        year = next_month.year
        month = [next_month.month, MONTHS[next_month.month]].join(' ')
      else
        year = today.year
        month = [today.month, MONTHS[today.month]].join(' ')
      end

      $month_directory = "E:/Planillas/#{year}/#{month}"
      Helpers.mkdir "E:/Planillas/#{year}"
      Helpers.mkdir $month_directory
    end

    def today
      @_today ||= Date.today
    end

    def today_to_s
      @_today_to_s ||= today.strftime('%d-%m-%y')
    end


    def now_to_s
      Time.now.strftime('%d-%m-%y %h:%M:%s')
    end

    def do_sum_in_all_files
      Dir.glob("#{$month_directory}/*.csv").each do |file|
        total_global = total_propio = total_tercero = 0

        csv_file = CSV.read(file)
        rows_number = csv_file.size - 1

        unless csv_file[rows_number][1].match(/Tercero =>/i)

          csv_file.each do |csv|
            total_global += csv[5].to_i

            if csv[6] =~ /\w+/i
              total_tercero += csv[5].to_i
            else
              total_propio += csv[5].to_i
            end
          end

          CSV.open(file, 'ab') do |csv|
            csv << []
            csv << [today_to_s, "Total => $ #{total_global}"]
            csv << [today_to_s, "Propio => $ #{total_propio}"]
            csv << [today_to_s, "Tercero => $ #{total_tercero}"]
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

    def two_months_ago
      @_two_months_ago ||= today.advance(months: -2).to_s
    end

    def months_ago(x)
      @_months_ago ||= {}
      @_months_ago[x] ||= today.advance(months: -x).to_s
    end

    private

    def delete_innecesary_spaces(string)
      string.strip.split(' ').join(' ')
    end
  end
end
