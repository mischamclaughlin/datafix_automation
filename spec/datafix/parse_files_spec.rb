require_relative '../spec_helper'

RSpec.describe DataFix::ParseFiles do
  let(:config) do
    {
      'files' => {},
      'settings' => {}
    }
  end

  let(:parser) { described_class.new(input_file: 'dummy.xlsx', config: config) }

  describe '#index_for_header' do
    let(:headers) { ['Name', 'Email Address', 'Subscription ID'] }

    it 'returns the correct index for a given header name' do
      expect(parser.send(:index_for_header, headers, 'Email Address')).to eq(1)
    end

    it 'is case insensitive and ignores whitespace' do
      expect(parser.send(:index_for_header, headers, ' subscription id ')).to eq(2)
    end

    it 'raises an error if the header is not found' do
      expect {
        parser.send(:index_for_header, headers, 'Nonexistent Header')
      }.to raise_error("Column 'Nonexistent Header' not found in headers: #{headers.inspect}")
    end
  end

  describe '#indices_for_headers' do
    let(:headers) { ['Name', 'Email Address', 'Subscription ID'] }

    it 'returns an array of indices for given header names' do
      indices = parser.send(:indices_for_headers, headers, ['Name', 'Subscription ID'])
      expect(indices).to eq([0, 2])
    end
  end

  describe '#manual_mode?' do
    it 'returns true if manual mode is enabled in settings' do
      parser_with_manual = described_class.new(input_file: 'dummy.xlsx', config: { 'settings' => { 'manual' => true } })
      expect(parser_with_manual.send(:manual_mode?)).to be true
    end

    it 'returns false if manual mode is not enabled' do
      expect(parser.send(:manual_mode?)).to be false
    end
  end

  describe '#target_columns_enabled?' do
    it 'returns true if target columns setting is enabled' do
      parser_with_target = described_class.new(input_file: 'dummy.xlsx', config: { 'settings' => { 'target_columns' => true } })
      expect(parser_with_target.send(:target_columns_enabled?)).to be true
    end

    it 'returns false if target columns setting is not enabled' do
      expect(parser.send(:target_columns_enabled?)).to be false
    end
  end

  describe '#parse_files' do
    it 'raises an error for unsupported file types' do
      expect {
        parser.send(:parse_files, 'unsupported.txt')
      }.to raise_error("Unsupported file type: unsupported.txt")
    end

    it 'parses Excel files' do
      sheet_double = double('sheet',
                            row: ['Header1', 'Header2'],
                            last_row: 1)          # so (2..last_row) is empty
      allow(sheet_double).to receive(:cell).and_return(nil)

      workbook_double = double('workbook', sheet: sheet_double)
      allow(Roo::Spreadsheet).to receive(:open).and_return(workbook_double)

      expect {
        parser.send(:parse_files, 'test.xlsx')
      }.not_to raise_error
    end

    it 'parses YAML files' do
      yaml_content = [
        {
          'type' => 'table',
          'data' => [
            { 'main' => 'value1', 'other' => 'x' }
          ]
        }
      ]
      allow(YAML).to receive(:load_file).and_return(yaml_content)

      expect {
        parser.send(:parse_files, 'test.yaml')
      }.not_to raise_error
    end
  end
end
