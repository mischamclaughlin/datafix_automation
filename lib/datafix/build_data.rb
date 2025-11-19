module DataFix
  class BuildData
    def initialize(parsed_data:, parsed_php_admin_data:, config: DataFix.config)
      @parsed_input_data = parsed_data
      @parsed_php_admin_data = parsed_php_admin_data
      @config = config
      @settings = @config['settings'] || {}
      @old_data =
        if @settings.key?('old_data')
          !!@settings['old_data']
        else
          true
        end
    end

    def build_all_data(options = 'all')
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

            data = {
              'client_business_guid': main_value,
            }

            if options == 'all' || options == 'accounts'
              next if built_data.any? { |d| d[:client_business_guid] == main_value } && options == 'accounts'
              data['client_business_id'] = php_entry[main_value]['client_business_id'].to_i
              data['zuora_account_number'] = nested_data['zuora_account_number_for_client'].strip
              if @old_data
                data['old_zuora_account_number'] = php_entry[main_value]['zuora_account_number']&.strip || nil
              end
            end

            if options == 'all' || options == 'subscriptions'
              data['sub_id'] = php_entry[main_value]['sub_id'].to_i
              data['zuora_subscription_number'] = zuora_number
              if @old_data
                data['old_zuora_subscription_number'] = php_entry[main_value]['zuora_subscription_number']&.strip || nil
              end
            end

            built_data << data
          end
        end
      end

      built_data
    end
  end
end
