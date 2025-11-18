module DataFix
  class BuildData
    def initialize(parsed_data:, parsed_php_admin_data:)
      @parsed_input_data = parsed_data
      @parsed_php_admin_data = parsed_php_admin_data
    end

    def build_account_data
      built_data = []

      @parsed_input_data.each do |entry|
        entry.each do |main_value, nested_data|
          @parsed_php_admin_data.each do |php_entry|
            if php_entry.key?(main_value)
              data = {
                'client_business_guid': main_value,
                'client_business_id': php_entry[main_value]['client_business_id'].to_i,
                'zuora_account_number': nested_data['zuora_account_number_for_client'].strip
              }
              built_data << data if built_data.none? { |d| d[:client_business_guid] == data[:client_business_guid] }
            end
          end
        end
      end

      built_data
    end

    def build_subscription_data
      built_data = []
      seen_main_values = []

      @parsed_input_data.each do |entry|
        entry.each do |main_value, nested_data|
          @parsed_php_admin_data.each do |php_entry|
            next unless php_entry.key?(main_value)

            if php_entry[main_value]['zuora_subscription_number']
              zuora_number = php_entry[main_value]['zuora_subscription_number'].strip
            elsif seen_main_values.include?(main_value)
              zuora_number = nested_data['subscription_number_created_2'].strip
            else
              zuora_number = nested_data['subscription_number_created_1'].strip
              seen_main_values << main_value
            end

            built_data << {
              'client_business_guid': main_value,
              'sub_id': php_entry[main_value]['sub_id'].to_i,
              'zuora_subscription_number': zuora_number
            }
          end
        end
      end

      built_data
    end
  end
end
