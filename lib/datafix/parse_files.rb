require 'roo'
require 'yaml'

module DataFix
  class ParseFiles
    attr_reader :input_file

    def initialize(input_file:, config: DataFix.config)
      @input_file = input_file
      @config = config
      @files = @config['files'] || {}
      @settings = @config['settings'] || {}
    end
    
    def parse_files(file_path)
      case File.extname(file_path).downcase
      when '.xlsx', '.xls'
        parse_xlsx(file_path)
      when '.yaml', '.yml'
        parse_yaml(file_path)
      else
        raise "Unsupported file type: #{file_path}"
      end
    end

    private

    def normalize_header(header)
      header.to_s.strip.downcase.gsub(/\s+/, '_')
    end

    def header_key(header)
      normalize_header(header).downcase.gsub(/\s+/, '_')
    end

    def index_for_header(headers, name)
      target = normalize_header(name)
      idx = headers.index { |h| normalize_header(h) == target }
      return idx if idx

      raise "Column '#{name}' not found in headers: #{headers.inspect}"
    end

    def indices_for_headers(headers, names)
      Array(names).map { |name| index_for_header(headers, name) }
    end

    def manual_mode?
      !!@settings['manual']
    end

    def target_columns_enabled?
      !!@settings['target_columns']
    end

    def parse_xlsx(file_path)
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)

      headers = sheet.row(1)

      if manual_mode?
        target_indices = run_manual_parse(headers)
      elsif target_columns_enabled? && @settings['target_columns_input']
        target_indices = indices_for_headers(headers, @settings['target_columns_input'])
      else
        target_indices = (0...headers.size).to_a
      end

      main_col_index =
        if @settings['lookup_column_input']
          index_for_header(headers, @settings['lookup_column_input'])
        else
          target_indices.first || 0
        end

      data = []
      (2..sheet.last_row).each do |row_num|
        main_value = sheet.cell(row_num, main_col_index + 1)
        nested_data = {}
        
        target_indices.each do |col_index|
          next if col_index == main_col_index

          col_name = header_key(headers[col_index])
          nested_data[col_name] = sheet.cell(row_num, col_index + 1)
        end
        
        data << { main_value => nested_data }
      end

      data
    end

    def parse_yaml(file_path)
      content = YAML.load_file(file_path)
      
      table_entry = content.find { |entry| entry['type'] == "table" }

      return [] if table_entry.nil? || table_entry.empty?

      table_data = table_entry['data']
      return [] if table_data.nil? || table_data.empty?

      available_keys = table_data.first.keys

      if manual_mode?
        target_indices = run_manual_parse(available_keys)
        main_col_index = target_indices.first || 0
        value_keys = target_indices.drop(1).map { |idx| available_keys[idx] }
        main_key = available_keys[main_col_index]
      else
        main_key = @settings['lookup_column_php_admin'] || available_keys.first

        if target_columns_enabled? && @settings['target_columns_php_admin']
          value_keys = Array(@settings['target_columns_php_admin'])
        else
          value_keys = available_keys - [main_key]
        end
      end

      data = []
      table_data.each do |record|
        main_value = record[main_key]
        nested_data = {}
        
        value_keys.each do |key|
          nested_data[key] = record[key]
        end
        
        data << { main_value => nested_data }
      end

      data
    end

    def run_manual_parse(available_keys)
      puts "Available columns:"
      
      available_columns = {}
      available_keys.each_with_index do |key, index|
        puts " #{index}: #{key}"
        available_columns[index] = key
      end

      get_target_columns(available_columns)
    end

    def get_target_columns(cols)
      target_cols = []
      puts "Enter the index of the main column to use as key:"
      main_col = gets.chomp.to_i
      target_cols << main_col
      while true
        puts "Enter the index of a column to include (or 'exit' to finish):"
        input = gets.chomp
        break if input.downcase == 'exit'

        column_index = input.to_i
        next unless cols.key?(column_index)

        target_cols << column_index
      end
      target_cols
    end
  end
end
