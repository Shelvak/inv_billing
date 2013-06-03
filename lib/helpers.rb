class Helpers
  class << self
    def create_csv_for(owner, month_directory)
      owner_name = delete_innecesary_spaces(owner)
      @@owner_file = "#{month_directory}/#{owner_name}.csv"
                
      unless File.exists? @@owner_file
        CSV.open(@@owner_file, 'ab') do |csv|
          3.times { csv << [] }
          csv << [ '  ', "Tramites para #{owner.upcase}" ]
          2.times { csv << [] }
        end
      end
    end

    def add_to_csv(contents)
      CSV.open(@@owner_file, 'ab') do |csv|
        contents.each { |c| csv << c }
      end
    end

    def mkdir(dir)
      begin
        Dir.mkdir dir
      rescue
        puts 'Ya existe'
      end
    end

    def log_error(error)
      CSV.open('error.csv', 'ab') do |csv|
        csv << [error]
      end
    end
  end

  private

  def self.delete_innecesary_spaces(string)
    new_string = string[-1] == ' ' ? string.chomp(' ') : string
    new_string[-1] == ' ' ? delete_innecesary_spaces(new_string) : new_string
  end
end
