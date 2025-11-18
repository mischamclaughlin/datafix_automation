require_relative 'spec_helper'

RSpec.describe DataFix::ParseFiles do
  describe '#build_account_data' do
    let(:parsed_data) do
      [
        {
          'guid-123' => {
            'zuora_account_number_for_client' => ' ZUORA-001 '
          }
        },
        {
          'guid-456' => {
            'zuora_account_number_for_client' => ' ZUORA-002 '
          }
        }
      ]
    end

    let(:parsed_php_admin_data) do
      [
        {
          'guid-123' => {
            'client_business_id' => '1001'
          }
        },
        {
          'guid-456' => {
            'client_business_id' => '1002'
          }
        }
      ]
    end

    it 'builds account data correctly' do
      builder = DataFix::BuildData.new(
        parsed_data: parsed_data,
        parsed_php_admin_data: parsed_php_admin_data
      )

      result = builder.build_account_data

      expect(result).to eq([
        {
          client_business_guid: 'guid-123',
          client_business_id: 1001,
          zuora_account_number: 'ZUORA-001'
        },
        {
          client_business_guid: 'guid-456',
          client_business_id: 1002,
          zuora_account_number: 'ZUORA-002'
        }
      ])
    end

    it 'handles cases with no matching PHP admin data gracefully' do
      parsed_php_admin_data_empty = []

      builder = DataFix::BuildData.new(
        parsed_data: parsed_data,
        parsed_php_admin_data: parsed_php_admin_data_empty
      )

      result = builder.build_account_data

      expect(result).to eq([])
    end
  end

  describe '#build_subscription_data' do
    let(:parsed_data) do
      [
        {
          'guid-123' => {
            'subscription_number_created_1' => ' SUB-001-A ',
            'subscription_number_created_2' => ' SUB-001-B '
          }
        },
        {
          'guid-456' => {
            'subscription_number_created_1' => ' SUB-002-A ',
            'subscription_number_created_2' => ' SUB-002-B '
          }
        }
      ]
    end

    let(:parsed_php_admin_data) do
      [
        {
          'guid-123' => {
            'sub_id' => '2001',
            'zuora_subscription_number' => nil
          }
        },
        {
          'guid-456' => {
            'sub_id' => '2002',
            'zuora_subscription_number' => ' ZUORA-SUB-002 '
          }
        }
      ]
    end

    it 'builds subscription data correctly' do
      builder = DataFix::BuildData.new(
        parsed_data: parsed_data,
        parsed_php_admin_data: parsed_php_admin_data
      )

      result = builder.build_subscription_data

      expect(result).to eq([
        {
          client_business_guid: 'guid-123',
          sub_id: 2001,
          zuora_subscription_number: 'SUB-001-A'
        },
        {
          client_business_guid: 'guid-456',
          sub_id: 2002,
          zuora_subscription_number: 'ZUORA-SUB-002'
        }
      ])
    end

    it 'uses the second subscription number if the first has already been used' do
      parsed_data_with_duplicate = [
        {
          'guid-123' => {
            'subscription_number_created_1' => ' SUB-001-A ',
            'subscription_number_created_2' => ' SUB-001-B '
          }
        },
        {
          'guid-123' => {
            'subscription_number_created_1' => ' SUB-001-C ',
            'subscription_number_created_2' => ' SUB-001-D '
          }
        }
      ]

      builder = DataFix::BuildData.new(
        parsed_data: parsed_data_with_duplicate,
        parsed_php_admin_data: parsed_php_admin_data
      )

      result = builder.build_subscription_data

      expect(result).to eq([
        {
          client_business_guid: 'guid-123',
          sub_id: 2001,
          zuora_subscription_number: 'SUB-001-A'
        },
        {
          client_business_guid: 'guid-123',
          sub_id: 2001,
          zuora_subscription_number: 'SUB-001-D'
        }
      ])
    end

    it 'handles cases with no subscriptions gracefully' do
      empty_parsed_data = []

      builder = DataFix::BuildData.new(
        parsed_data: empty_parsed_data,
        parsed_php_admin_data: parsed_php_admin_data
      )

      result = builder.build_subscription_data

      expect(result).to eq([])
    end
  end
end
