# Travel Blog Project - Japan Trip 2025

## Project Overview

This Rails 8 application is being transformed from a simple notes template into a travel blog platform. The primary use case is to document a Japan trip in May 2025, allowing relatives (especially aged parents) to follow the journey in real-time.

## Core Features

### Data Model
- **Users**: Authentication with bcrypt, OTP support, admin capabilities
- **Trips**: Belong to users, represent a journey (e.g., "Japan 2025")
- **Days**: Belong to trips, contain the daily blog entries with markdown text

### Authorization Model (CanCan)
- **Guests** (not logged in): Can view trips and days (read-only)
- **Users** (logged in): Can create trips and days, edit/delete their own content
- **Admin**: Can do anything, including creating new users and managing all content

### Future Features
- **Image/Video Upload**: Active Storage for local file storage
- **Media Embedding**: Ability to insert uploaded images/videos into blog text
- **Rich Markdown**: Building on existing Redcarpet implementation

## Current Template Structure

### Models
- `User`: Authentication, authorization, OTP support
- `Note`: Example model showing patterns to follow (will be removed later)
- `Guest`: Null object pattern for unauthenticated users
- `Ability`: CanCan authorization rules

### Concerns (Reusable Patterns)
- `Constrainable`: Search query building (numerical and cross-column text search)
- `Pageable`: Pagination with search parameter preservation
- `Remarkable`: Markdown rendering with Redcarpet, custom image handling

### Controllers
- Standard CRUD pattern with CanCan authorization
- Flash messages for errors via `failure` helper
- Session-based authentication with `current_user`

### Views (HAML)
- Bootstrap 5 styling
- Turbo frames for dynamic content
- Reusable partials in `app/views/utils/`:
  - `crud/*`: Form helpers (text, area, select, check, password, buttons)
  - `search/*`: Search form components
  - `pagination/*`: Pagination links

### Testing (RSpec)
- Feature specs with Capybara (JavaScript enabled)
- FactoryBot for test data
- Database Cleaner for test isolation

## Code Analysis & Issues to Fix

### Critical Issues

1. ~~**Rails 8.1.1 Schema Format**: FIXED - Schema regenerated with `rails db:schema:dump` to use `ActiveRecord::Schema[8.1].define(...)` format~~

2. ~~**Missing `admin` Column**: FALSE ALARM - The `admin` boolean column exists in the schema (line 32), Rails automatically creates the `admin?` predicate method~~

3. ~~**Note Model Bug** (app/models/note.rb:43): FIXED - The `clean` method bug has been corrected to check `text.blank?` instead of `markdown.blank?`~~

4. ~~**Remarkable Concern References Non-existent Picture Model** (app/models/concerns/remarkable.rb:79): FIXED - The `preprocess_images` method has been removed~~

### Minor Issues

5. **Inconsistent Timestamp Precision**: Schema uses `precision: 6` for timestamps, but Rails 8 defaults to `precision: nil` (microseconds). Should be consistent.

6. **Missing User Admin Scope**: Users have an `admin` flag but no convenient scope like `User.admins` for querying admin users.

7. **Note Authorization Gap**: The `Ability` model allows all non-guest users to `:read` notes, but doesn't define who can `:create`, `:update`, or `:destroy` them. The NotesController uses `load_and_authorize_resource` which will fail for these actions.

8. **Guest Model Missing `id` Method**: The `Guest` class should probably have an `id` method returning `nil` for consistency with User objects, especially when used in forms or comparisons.

### Code Style Observations

9. **Good Patterns to Maintain**:
   - Constants for validation limits at top of models
   - `normalize_attributes` before_validation callbacks
   - Inverse associations specified
   - Default scopes for consistent ordering
   - Helpers for common UI patterns (center, col, pagination_links)
   - Comprehensive feature tests with clear contexts

10. **Documentation Needed**:
    - The `Constrainable` concern has complex regex logic that would benefit from comments
    - The `Remarkable` custom image syntax needs documentation for users

### Recommendations

11. **Active Storage**: Not yet configured. Will need to run `rails active_storage:install` and add configuration for local storage.

12. **Markdown Preview**: Consider adding live preview for markdown editing (Stimulus controller).

13. **Image Upload UI**: Will need to design how users upload images and get the markdown syntax to embed them.

## Next Steps

### Phase 1: Fix Critical Issues
- [x] Fix schema format for Rails 8.1.1
- [x] Fix `clean` method bug in Note model
- [x] Remove or fix Picture model reference in Remarkable concern
- [ ] Fix Note authorization rules in Ability model

### Phase 2: Create Trip & Day Models
- [ ] Generate Trip model (belongs_to :user)
- [ ] Generate Day model (belongs_to :trip)
- [ ] Add associations to User
- [ ] Create migrations
- [ ] Add validations and concerns
- [ ] Set up default scopes

### Phase 3: Trip & Day Controllers/Views
- [ ] Create TripsController with authorization
- [ ] Create DaysController with authorization
- [ ] Build Trip views (index, show, new, edit)
- [ ] Build Day views (index, show, new, edit)
- [ ] Add routes
- [ ] Update navigation

### Phase 4: Authorization & Testing
- [ ] Update Ability model for trips and days
- [ ] Create factories for trips and days
- [ ] Write feature specs for trips
- [ ] Write feature specs for days
- [ ] Test guest access (read-only)
- [ ] Test user access (own content only)
- [ ] Test admin access (everything)

### Phase 5: Active Storage & Media
- [ ] Install Active Storage
- [ ] Configure local storage
- [ ] Add image upload to days
- [ ] Update Remarkable concern for Active Storage
- [ ] Add image embedding to markdown
- [ ] Test image upload and display

### Phase 6: Polish
- [ ] Remove Note model and related code
- [ ] Add production deployment configuration
- [ ] Performance optimization
- [ ] SEO metadata for public trip pages
- [ ] Mobile responsive design verification

## Tech Stack
- Ruby 3.x
- Rails 8.1.1
- PostgreSQL
- HAML templates
- SASS stylesheets
- Bootstrap 5
- Turbo & Stimulus (Hotwire)
- Redcarpet (Markdown)
- CanCanCan (Authorization)
- BCrypt (Authentication)
- ROTP/RQRCode (OTP)
- RSpec + Capybara (Testing)
