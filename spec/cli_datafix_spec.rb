require_relative 'spec_helper'
require 'stringio'

RSpec.describe 'bin/datafix CLI' do
  def capture_stdout
    original_stdout = $stdout
    fake = StringIO.new
    $stdout = fake
    yield
    fake.string
  ensure
    $stdout = original_stdout
  end

  def run_cli(*args)
    script_path = File.expand_path('../bin/datafix', __dir__)
    original_argv = ARGV.dup
    ARGV.replace(args)
    load script_path
  ensure
    ARGV.replace(original_argv)
  end

  let(:parsed_input) do
    [{ 'guid-1' => { 'foo' => 'bar' } }]
  end

  let(:parsed_php) do
    [
      {
        'guid-1' => {
          'client_business_id' => 1,
          'sub_id' => 10,
          'zuora_subscription_number' => 'SUB-1'
        }
      }
    ]
  end

  let(:parser_double) { instance_double(DataFix::ParseFiles) }
  let(:builder_double) { instance_double(DataFix::BuildData) }

  before do
    # Avoid writing real files/directories during tests
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:write)

    allow(DataFix::ParseFiles).to receive(:new).and_return(parser_double)
    allow(parser_double).to receive(:parse_files).and_return(parsed_input, parsed_php)

    allow(DataFix::BuildData).to receive(:new).and_return(builder_double)
  end

  it 'runs with default config and writes JSON for accounts and subscriptions' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])

    stdout = capture_stdout { run_cli }

    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'respects the --only accounts option' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    expect(builder_double).not_to receive(:build_subscription_data)

    stdout = capture_stdout { run_cli('--only', 'accounts') }

    expect(stdout).to include('"accounts"')
    expect(stdout).not_to include('"subscriptions"')
  end

  it 'respects the --only subscriptions option' do
    expect(builder_double).not_to receive(:build_account_data)
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])

    stdout = capture_stdout { run_cli('--only', 'subscriptions') }

    expect(stdout).not_to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'respects the --only both option' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])

    stdout = capture_stdout { run_cli('--only', 'both') }

    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'defaults to both when --only is not provided' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])
    stdout = capture_stdout { run_cli }
    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'writes output files to the specified directory' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])

    stdout = capture_stdout { run_cli('--output', 'custom_output') }

    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'uses the specified config file' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])
    stdout = capture_stdout { run_cli('--config', 'custom_config.yaml') }
    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'prints help message with --help option' do
    stdout = capture_stdout { run_cli('--help') }
    expect(stdout).to include('Usage:')
  end

  it 'prints version with --version option' do
    stdout = capture_stdout { run_cli('--version') }
    expect(stdout).to match(/DataFix version \d+\.\d+\.\d+/)
  end

  it 'handles manual mode flag' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])
    stdout = capture_stdout { run_cli('--manual') }
    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'handles target columns flag' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])
    stdout = capture_stdout { run_cli('--target-columns') }
    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'handles both manual mode and target columns flags' do
    allow(builder_double).to receive(:build_account_data).and_return([{ client_business_guid: 'guid-1' }])
    allow(builder_double).to receive(:build_subscription_data).and_return([{ client_business_guid: 'guid-1' }])
    stdout = capture_stdout { run_cli('--manual', '--target-columns') }
    expect(stdout).to include('"accounts"')
    expect(stdout).to include('"subscriptions"')
  end

  it 'raises an error for unknown --only values' do
    expect {
      capture_stdout { run_cli('--only', 'invalid') }
    }.to raise_error(SystemExit)
  end

  context 'when the parser raises' do
    before do
      allow(parser_double).to receive(:parse_files).and_raise('Unsupported file type: unsupported.txt')
    end

    it 'propagates the error' do
      expect {
        capture_stdout { run_cli }
      }.to raise_error('Unsupported file type: unsupported.txt')
    end
  end

  context 'when parsed data is empty' do
    let(:parsed_input) { [] }
    let(:parsed_php) { [] }

    it 'handles empty parsed data gracefully' do
      allow(builder_double).to receive(:build_account_data).and_return([])
      allow(builder_double).to receive(:build_subscription_data).and_return([])

      stdout = capture_stdout { run_cli }

      expect(stdout).to include('"accounts": []')
      expect(stdout).to include('"subscriptions": []')
    end
  end
end
