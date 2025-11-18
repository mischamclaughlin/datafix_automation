require 'yaml'

module DataFix
  CONFIG_PATHS = [
    File.expand_path('../../config/datafix.yml', __dir__),
    File.expand_path('../config/datafix.yml', __dir__),
    File.expand_path('config/datafix.yml', Dir.pwd)
  ].freeze

  def self.config
    @config ||= begin
      path = CONFIG_PATHS.find { |p| File.exist?(p) }
      path ? (YAML.load_file(path) || {}) : {}
    end
  end
end

require 'datafix/version'
require 'datafix/parse_files'
require 'datafix/build_data'
