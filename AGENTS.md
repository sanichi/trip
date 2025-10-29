# Agent Guidelines for Rails 8 App

## Build/Test Commands
- **Tests**: `bundle exec rspec` (all), `bundle exec rspec spec/models/user_spec.rb` (single file), `bundle exec rspec spec/models/user_spec.rb:25` (specific line)
- **Database**: `rails db:create db:migrate`, `rails db:reset` (test data)
- **Assets**: `rails assets:precompile` (production), `rails assets:clean`
- **Server**: `rails server` or `bin/dev`

## Code Style
- **Language**: Ruby 3.x, Rails 8.0.2
- **Views**: HAML templates (`.html.haml`), not ERB
- **Styling**: SASS (`.sass`), Bootstrap 5 classes
- **Models**: Use validations, scopes, constants at top (e.g., `MAX_EMAIL = 50`)
- **Controllers**: Inherit from ApplicationController, use CanCan authorization
- **Naming**: Snake_case for files/methods, PascalCase for classes
- **Error Handling**: Use `flash[:alert]` for user errors, `rescue_from` for exceptions
- **Testing**: RSpec with FactoryBot, Capybara for features
- **Authentication**: `has_secure_password`, session-based with OTP support
- **Dependencies**: Check Gemfile before adding gems
- **Imports**: Use `require_relative` for local files, standard `require` for gems