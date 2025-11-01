# Travel Blog Project - Japan Trip 2025

## Project Overview

This Rails 8 application is being transformed from a simple notes template into a travel blog platform. The primary use case is to document a Japan trip in May 2025, allowing relatives (especially aged parents) to follow the journey in real-time.

## Core Features

### Data Model
- **Users**: Authentication with bcrypt, OTP support, admin capabilities
- **Trips**: Belong to users, represent a journey with start/end dates (max 90 days)
- **Days**: Nested under trips, represent individual days with date, title, notes (text), and draft status. Days calculate their sequence dynamically based on date position within the trip.

### Authorization Model (CanCan)
- **Guests** (not logged in): Can view trips and days (read-only)
- **Users** (logged in): Can create trips and days, edit/delete their own content (days inherit trip ownership via association traversal)
- **Admin**: Can do anything, including creating new users and managing all content

### Future Features
- **Image/Video Upload**: Active Storage for local file storage
- **Media Embedding**: Ability to insert uploaded images/videos into blog text
- **Rich Markdown**: Building on existing Redcarpet implementation

## Current Template Structure

### Models
- `User`: Authentication, authorization, OTP support
- `Trip`: Journey with title, start_date, end_date. Validates date ranges and prevents date changes that would orphan days
- `Day`: Individual day entries with date, title (max 50 chars), notes (text), draft boolean. Nested resource under Trip. Validates date falls within trip range and unique per trip.
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
  - `crud/*`: Form helpers (text, area, select, check, password, buttons) - **Enhanced to support nested resources by accepting arrays as model parameter**
  - `search/*`: Search form components
  - `pagination/*`: Pagination links
- Days displayed inline on Trip show page (no separate days index)

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

5. ~~**Inconsistent Timestamp Precision**: FALSE ALARM - The schema doesn't explicitly set precision, it uses Rails/PostgreSQL defaults (microseconds), which is correct for Rails 8.~~

6. ~~**Note Authorization Gap**: FIXED - Users can now `:create` notes and `:update`/`:destroy` their own notes (where `user_id` matches). Tests updated and passing.~~

7. ~~**Guest Model Missing `id` Method**: FALSE ALARM - The `Guest` model is a null object pattern and should NOT mirror all User attributes. It only needs methods the app actually calls for permission checking (like `guest?`, `admin?`, `name`). Adding fake attributes like `id` or `email` would mask bugs in calling code.~~

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

## Recent Achievements

### Nested Resources Implementation (Days under Trips)
Successfully implemented Days as a nested resource with several technical highlights:

1. **Enhanced CRUD Form Helper**: Modified `utils/crud/_form.html.haml` to support nested resources by:
   - Detecting when `object` parameter is an array (e.g., `[@trip, @day]`)
   - Extracting actual object for validation checks while preserving array for `form_with`
   - Passing both `cancel_path` and `delete_path` explicitly to handle nested routes

2. **Smart Date Management**:
   - Days list automatically shown on trip show page (no separate index)
   - "New Day" button appears only when slots available and user authorized
   - New day form pre-populates with first available date slot
   - Prevents creating days outside trip date range
   - Prevents modifying trip dates if it would invalidate existing days

3. **User Experience Features**:
   - Draft indicator (📝 emoji) on trip page for work-in-progress days
   - Dynamic day labels ("Day 1", "Day 2") calculated from date position
   - Sparse day support (can have Day 1, 3, 5 without 2 and 4)

## Next Steps

### Phase 1: Fix Critical Issues
- [x] Fix schema format for Rails 8.1.1
- [x] Fix `clean` method bug in Note model
- [x] Remove or fix Picture model reference in Remarkable concern
- [x] Fix Note authorization rules in Ability model

### Phase 2: Create Trip & Day Models
- [x] Generate Trip model (belongs_to :user)
- [x] Add association to User (has_many :trips)
- [x] Create migration with title, start_date, end_date
- [x] Add validations (title, dates, date range, max 90 days)
- [x] Add normalize_attributes callback
- [x] Set up default scope (created_at desc)
- [x] Fix namespace collision (renamed Trip module to Trips)
- [x] Generate Day model (belongs_to :trip)
- [x] Add associations for days (Trip has_many :days, dependent: :destroy)
- [x] Add unique index on [trip_id, date]
- [x] Implement dynamic sequence calculation (day number based on date offset from trip start)
- [x] Add validation preventing trip date changes that would orphan existing days

### Phase 3: Trip & Day Controllers/Views
- [x] Create TripsController with authorization
- [x] Build Trip views (index, show, new, edit, form partial)
- [x] Add routes for trips
- [x] Update navigation with Trips link
- [x] Create trip locale file (trip.yml)
- [x] Create DaysController with authorization (nested under trips)
- [x] Build Day views (show, new, edit, form partial - no index, days shown on trip page)
- [x] Add nested routes for days (except index)
- [x] Create day locale file (day.yml)
- [x] Add draft emoji indicator (📝) to trip show page for draft days
- [x] Implement "New Day" button with slot availability check
- [x] Auto-populate first available date slot when creating new day
- [x] Create trip_first_available_slot helper method

### Phase 4: Authorization & Testing
- [x] Update Ability model for trips (guests read, users manage own, admins all)
- [x] Create factory for trips
- [x] Write feature specs for trips (11 tests, all passing)
- [x] Test guest access (read-only) ✓
- [x] Test user access (own content only) ✓
- [x] Test admin access (everything) ✓
- [x] Update Ability model for days (using trip association traversal: `trip: { user_id: user.id }`)
- [x] Create factory for days
- [x] Write feature specs for days (16 tests, all passing)
- [x] Test CRUD operations for admins, users, and guests ✓
- [x] Test date validations (day within trip range) ✓
- [x] Test trip date change prevention when it would orphan days ✓
- [x] Test slot availability and default date assignment ✓
- [x] Test draft status handling ✓

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
