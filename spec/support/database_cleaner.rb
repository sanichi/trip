# http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/

RSpec.configure do |config|
  # Get a clean slate before the suite runs.
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # Default strategy is transactions (fastest).
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # But for selenium tests, truncation works better.
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  # Cleaning before and after each test.
  config.before(:each) { DatabaseCleaner.start }
  config.after(:each)  { DatabaseCleaner.clean }
end
