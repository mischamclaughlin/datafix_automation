require 'roo'
require 'yaml'

module DataFix
  class ParseFiles
    attr_reader :input_file

    def initialize(input_file:)
      @input_file = input_file
    end
    
    def parse_files(file_path)
      if file_path.end_with?('.xlsx', '.xls')
        parse_xlsx(file_path)
      elsif file_path.end_with?('.yaml', '.yml')
        parse_yaml(file_path)
      else
        raise "Unsupported file type: #{file_path}"
      end
    end

    private

    def parse_xlsx(file_path)
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)

      available_columns = {}

      puts 'Available Columns:'
      sheet.row(1).each_with_index do |header, index|
        puts "#{index}: #{header}"
        available_columns[index] = header
      end

      target_cols = get_target_columns(available_columns)
      main_col_index = target_cols[0]

      data = []
      (2..sheet.last_row).each do |row_num|
        main_value = sheet.cell(row_num, main_col_index + 1)
        nested_data = {}
        
        target_cols[1..-1].each do |col_index|
          col_name = available_columns[col_index].strip.downcase.gsub(' ', '_')
          nested_data[col_name] = sheet.cell(row_num, col_index + 1)
        end
        
        data << { main_value => nested_data }
      end
      
      puts data
      puts
      data
    end

    def parse_yaml(file_path)
      content = YAML.load_file(file_path)
      
      table_entry = content.find { |entry| entry['type'] == "table" }

      if table_entry.nil? || table_entry.empty?
        puts 'No data found in the specified table.'
        return []
      end

      table_data = table_entry['data']
      if table_data.nil? || table_data.empty?
        puts 'No data found in the specified table.'
        return []
      end

      available_keys = table_data.first.keys
      
      puts 'Available Keys:'
      available_keys.each_with_index do |key, index|
        puts "#{index}: #{key}"
      end

      available_columns = {}
      available_keys.each_with_index { |key, idx| available_columns[idx] = key }

      target_cols = get_target_columns(available_columns)
      main_col_index = target_cols[0]
      main_key = available_keys[main_col_index]

      data = []
      table_data.each do |record|
        main_value = record[main_key]
        nested_data = {}
        
        target_cols[1..-1].each do |col_index|
          key = available_keys[col_index]
          nested_data[key] = record[key]
        end
        
        data << { main_value => nested_data }
      end
      puts data
      puts
      data
    end

    def get_target_columns(cols)
      puts
      target_cols = []
      puts 'Enter the Main lookup column (usually GUID): '
      main_col = gets.chomp.to_i
      target_cols << main_col
      while true
        print 'Enter the column number to extract (or type "exit" to quit): '
        input = gets.chomp
        break if input.downcase == 'exit'

        column_index = input.to_i
        unless cols.key?(column_index)
          puts 'Invalid column number. Please try again.'
          next
        end
        target_cols << column_index
      end
      puts
      target_cols
    end
  end
end

# DataFix::ParseFiles.new(
#   input_file: '/Users/mischa.mclaughlin/Desktop/datafix/Untitled-2.yaml'
# ).parse_files('/Users/mischa.mclaughlin/Desktop/datafix/Untitled-2.yaml')