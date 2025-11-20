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

    def build_account_data
      build_all_data('accounts')
    end

    def build_subscription_data
      build_all_data('subscriptions')
    end

    def build_all_data(options = 'all')
      include_accounts = options == 'all' || options == 'accounts'
      include_subscriptions = options == 'all' || options == 'subscriptions'

      built_data = []
      seen_accounts = {}
      subscription_counts = Hash.new(0)

      @parsed_input_data.each do |entry|
        entry.each do |main_value, nested_data|
          php_data = php_data_for(main_value)
          next unless php_data

          nested_data ||= {}
          client_guid = main_value.to_s

          data = { client_business_guid: client_guid }

          if include_accounts
            if options == 'accounts' && seen_accounts[client_guid]
              next
            end

            client_business_id = fetch_value(php_data, 'client_business_id')
            data[:client_business_id] = client_business_id.to_i if client_business_id

            account_number = clean_string(fetch_value(nested_data, 'zuora_account_number_for_client'))
            data[:zuora_account_number] = account_number if account_number

            if @old_data
              old_account = clean_string(fetch_value(php_data, 'zuora_account_number'))
              data[:old_zuora_account_number] = old_account if old_account
            end

            seen_accounts[client_guid] = true if options == 'accounts'
          end

          if include_subscriptions
            sub_id = fetch_value(php_data, 'sub_id')
            data[:sub_id] = sub_id.to_i if sub_id

            old_subscription = clean_string(fetch_value(php_data, 'zuora_subscription_number'))

            new_subscription = nil
            occurrence = subscription_counts[client_guid]
            sub_key = occurrence.zero? ? 'subscription_number_created_1' : 'subscription_number_created_2'
            new_subscription = clean_string(fetch_value(nested_data, sub_key))
            subscription_counts[client_guid] += 1 if new_subscription

            data[:zuora_subscription_number] = new_subscription if new_subscription
            data[:old_zuora_subscription_number] = old_subscription if @old_data
          end

          built_data << data
        end
      end

      built_data
    end

    private

    def php_data_for(main_value)
      @parsed_php_admin_data.each do |php_entry|
        php_data = fetch_value(php_entry, main_value)
        return php_data unless php_data.nil?
      end
      nil
    end

    def fetch_value(hash, key)
      return nil unless hash

      return hash[key] if hash.key?(key)

      string_key = key.to_s
      return hash[string_key] if hash.key?(string_key)

      symbol_key = key.respond_to?(:to_sym) ? key.to_sym : nil
      return hash[symbol_key] if symbol_key && hash.key?(symbol_key)

      nil
    end

    def clean_string(value)
      return nil if value.nil?

      stripped = value.to_s.strip
      stripped.empty? ? nil : stripped
    end
  end
end
