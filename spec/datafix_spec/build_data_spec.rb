require_relative '../spec_helper'

RSpec.describe DataFix::BuildData do
  describe '#build_all_data' do
    let(:parsed_data) do
      [
        {
          'business_guid_1': {
            'zuora_account_number_for_client': 'A0001',
            'subscription_number_created_1': 'S0001',
            'subscription_number_created_2': 'S0002'
          },
          'business_guid_2': {
            'zuora_account_number_for_client': 'A0002',
            'subscription_number_created_1': 'S0003',
            'subscription_number_created_2': 'S0004'
          }
        }
      ]
    end

    let(:parsed_php_admin_data) do
      [
        {
          'business_guid_1': {
            'client_business_id': '101',
            'zuora_account_number': 'OLD_A0001',
            'sub_id': '201',
            'zuora_subscription_number': 'OLD_S0001'
          },
          'business_guid_2': {
            'client_business_id': '102',
            'zuora_account_number': 'OLD_A0002',
            'sub_id': '202',
            'zuora_subscription_number': nil
          }
        }
      ]
    end

    let(:config) do
      {
        'settings': {
          'old_data': true
        }
      }
    end

    subject do
      DataFix::BuildData.new(
        parsed_data: parsed_data,
        parsed_php_admin_data: parsed_php_admin_data,
        config: config
      )
    end

    it 'builds all data correctly' do
      result = subject.build_all_data('all')
      expect(result).to eq([
        {
          client_business_guid: 'business_guid_1',
          client_business_id: 101,
          zuora_account_number: 'A0001',
          old_zuora_account_number: 'OLD_A0001',
          sub_id: 201,
          zuora_subscription_number: 'S0001',
          old_zuora_subscription_number: 'OLD_S0001'
        },
        {
          client_business_guid: 'business_guid_2',
          client_business_id: 102,
          zuora_account_number: 'A0002',
          old_zuora_account_number: 'OLD_A0002',
          sub_id: 202,
          zuora_subscription_number: 'S0003',
          old_zuora_subscription_number: nil
        }
      ])
    end
  end
end
