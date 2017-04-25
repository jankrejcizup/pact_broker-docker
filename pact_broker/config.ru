require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'
require 'delegate'

class DatabaseLogger < SimpleDelegator
  def info *args
    __getobj__().debug(*args)
  end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Sequel::DATABASES.each { |db| db.disconnect }
    end
  end
end

DATABASE_CREDENTIALS = {
  adapter: "postgres",
  user: ENV['PACT_BROKER_DATABASE_USERNAME'],
  password: ENV['PACT_BROKER_DATABASE_PASSWORD'],
  host: ENV['PACT_BROKER_DATABASE_HOST'],
  database: ENV['PACT_BROKER_DATABASE_NAME']
}

app = PactBroker::App.new do | config |
  config.logger = ::Logger.new($stdout)
  config.logger.level = Logger::WARN
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(logger: DatabaseLogger.new(config.logger), encoding: 'utf8'))
  config.database_connection.timezone = :utc
end

run app
