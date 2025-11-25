# Travel Blog Project - Japan Trip 2026

## Project Overview

This Rails 8 application is being transformed from a simple notes template into a travel blog platform. The primary use case is to document a Japan trip in May 2025, allowing relatives (especially aged parents) to follow the journey in real-time.

## Core Features

### Data Model
- **Users**: Authentication with bcrypt, OTP support, admin capabilities
- **Trips**: Belong to users, represent a journey with start/end dates (max 90 days)
- **Days**: Nested under trips, represent individual days with date, title, notes (text), and draft status. Days calculate their sequence dynamically based on date position within the trip.
- **Images**: Belong to users, use Active Storage for file management. Automatic processing: resize (max 1000px), compress (under 3MB), extract EXIF (GPS/date). Supports JPEG, PNG, WebP.

### Authorization Model (CanCan)
- **Guests** (not logged in): Can view trips and days (read-only)
- **Users** (logged in): Can create trips and days, edit/delete their own content (days inherit trip ownership via association traversal)
- **Admin**: Can do anything, including creating new users and managing all content

### Future Features
- **Image Embedding**: Ability to insert uploaded images into day notes via markdown
- **Video Upload**: Active Storage support for video files
- **Rich Markdown**: Enhanced markdown features building on existing Redcarpet implementation

## Current Template Structure

### Models
- `User`: Authentication, authorization, OTP support
- `Trip`: Journey with title, start_date, end_date. Validates date ranges and prevents date changes that would orphan days
- `Day`: Individual day entries with date, title (max 50 chars), notes (text), draft boolean. Nested resource under Trip. Validates date falls within trip range and unique per trip.
- `Image`: Photo uploads with Active Storage. Automatic processing (resize, compress), EXIF extraction (GPS, date taken). Belongs to user. Supports JPEG, PNG, WebP only.
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
- **Turbo caching disabled** in `_head.html.haml` via `turbo-prefetch: false` and `turbo-cache-control: no-preview`. This prevents stale session-dependent content (like the Admin link on the home page, which uses `session[:last_admin_page]`) from being shown during Turbo's prefetch or cached preview phases.
- Reusable partials in `app/views/utils/`:
  - `crud/*`: Form helpers (text, area, select, check, password, buttons) - **Enhanced to support nested resources by accepting arrays as model parameter**
  - `search/*`: Search form components
  - `pagination/*`: Pagination links
- Days displayed inline on Trip show page (no separate days index)

### Helpers
- **ApplicationHelper**: General utilities (pagination_links, center, col, home_page)
- **TripHelper**: Trip duration formatting, available slot detection
- **DayHelper**: Day date formatting with `day_date(day, long: false)` ("Mon May 11" or "Monday September 23"), day label formatting with `day_label(day, long: true)` ("Day 1" or "D1" for short form), ready badge, previous/next day navigation
- **ImageHelper**: Specialized formatters for consistent display:
  - `image_coordinates(lat, lon, decimals=4)`: Formats GPS as "N 57.1234 W 6.3847" with cardinal directions
  - `image_taken(taken, include_time=true)`: Formats dates as "17:31 Oct 5, 2025" or "Oct 5, 2025"
  - `image_size(byte_size)`: Smart size formatting (B/KB/MB with appropriate precision)
  - `image_type(content_type)`: Formats type as "JPG", "PNG", "WEBP" etc.
- **ViewerHelper**: Home page (viewer) specific helpers:
  - `day_window(days, current_day)`: Returns sliding window of 5 days centered on current
  - `show_nav_arrows?(days)`: Returns true if more than 5 days (arrows needed)
  - `first_day/last_day/previous_day/next_day`: Navigation helpers
  - `at_first_day?/at_last_day?`: Boundary detection for disabling arrows
  - `admin_return_path`: Returns last admin page from session or trips index

### Testing (RSpec)
- Feature specs with Capybara (JavaScript enabled)
- FactoryBot for test data
- Database Cleaner for test isolation
- Helper modules included in feature specs via `config.include DayHelper, type: :feature` in rails_helper.rb (avoids code duplication)

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

### Image Upload with Active Storage (Completed)
Successfully implemented image upload functionality with intelligent processing:

1. **Image Processing Pipeline**:
   - Automatic resize to max 1000px (longest dimension)
   - Smart compression to stay under 3MB
   - Fallback strategy: reduce to 500px at 70% quality if needed
   - Format preservation (no conversion - JPEG stays JPEG, etc.)
   - HEIC support via Apple's automatic conversion (macOS/iOS only)

2. **EXIF Data Extraction**:
   - GPS coordinates from both ifd0 (standard) and ifd3 (iPhone JPEGs)
   - Date taken extraction from multiple EXIF fields
   - Tested and verified with real iPhone photos

3. **Format Support**:
   - Accepts: JPEG, PNG, WebP
   - Rejects: HEIC/HEIF (with clear error messages), GIF
   - Client-side filtering via `accept` attribute
   - Server-side validation for security

4. **Code Simplification**:
   - Removed HEIC conversion logic (originally planned but unnecessary)
   - Reduced Image model from 354 to 323 lines
   - Removed format detection/conversion methods
   - Simplified processing to resize + compress only

5. **Production Verified**:
   - Tested on Alma Linux 9.6 production server
   - Works without HEIC decoder libraries
   - Apple devices auto-convert HEIC→JPEG preserving GPS/date

6. **Image Display Enhancements**:
   - Created specialized helper methods in ImageHelper for consistent formatting
   - GPS coordinates displayed with cardinal directions (N/S/E/W) instead of +/- signs
   - Smart file size formatting (auto-selects B/KB/MB with appropriate precision)
   - Date formatting with optional time display
   - Image show page redesigned with prominent ID header (for future embedding)
   - Index page restructured into compact 3-row format per image
   - Removed width/height/size search inputs (not needed for typical use)

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

### Public Home Page (Viewer) Implementation
Built a dedicated viewer experience for guests (family members) to read trip blogs:

1. **Trip Readiness Concept**:
   - Added `scope :ready` and `ready?` method to Trip model
   - A trip is "ready" when it has at least one non-draft day
   - Only ready trips appear on the home page

2. **Viewer Layout** (`app/views/layouts/viewer.html.haml`):
   - Clean, minimal layout without admin navigation
   - Always used for home page regardless of login status

3. **Six-Part Home Page Structure**:
   - **Part 1 - Trip Selector**: Dropdown menu for multiple trips, plain title for single trip
   - **Part 2 - Day Navigator**: Sliding window of 5 days with navigation arrows, all days shown as "Day N" format (hidden when only 1 day)
   - **Part 3 - Day Date**: Centered display of current day's full date (e.g., "Monday September 23") in blue bold text
   - **Part 4 - Day Title**: Centered h3 heading showing the current day's title
   - **Part 5 - Day Content**: Rendered markdown from selected day's notes
   - **Part 6 - Admin Link**: "Sign In" for guests, "Admin" for logged-in users

4. **Smart Navigation**:
   - Navigator section hidden when only 1 ready day
   - Next/previous arrows (◀ ▶) shown when 2+ days for navigation affordance (helps non-technical users discover the interface)
   - First/last arrows (⏮ ⏭) shown only when >5 days (when some days are hidden)
   - Current day shown as highlighted "Day N" in navigator, others as day links
   - Double arrows jump to first/last day, single arrows move one day

5. **Session Memory**:
   - Tracks last viewed day per trip
   - Tracks last admin page for "Admin" link return
   - Remembers position when switching between trips

6. **Default Selection Logic**:
   - Returning visitor → last viewed day from session
   - In-progress trip (today within dates) → latest ready day
   - Otherwise → first ready day of latest trip

7. **Feature Specs** (15 tests):
   - No ready trips, one trip, multiple trips scenarios
   - Day navigator visibility (hidden with 1 day, shown with 2+ days)
   - Arrow behavior (next/previous with 2+ days, first/last with 6+ days)
   - Draft day filtering
   - Guest vs logged-in user admin link

### Inline Draft Toggle (Turbo Stream)
Added ability to toggle a day's draft status directly from the trip show page without navigating away:

1. **Implementation**:
   - Clicking the ready badge (✓/✗) toggles the draft status in-place
   - Uses Turbo Stream for seamless updates without page reload
   - Only authorized users see clickable badges; others see static badges

2. **Files Modified**:
   - `config/routes.rb` - Added `patch :toggle_draft` member route on days
   - `app/controllers/days_controller.rb` - Added `toggle_draft` action
   - `app/models/ability.rb` - Added `alias_action :toggle_draft, to: :update` for authorization
   - `app/views/trips/show.html.haml` - Updated to use draft badge partial

3. **Files Added**:
   - `app/views/days/_draft_badge.html.haml` - Partial with Turbo Frame wrapper, renders as button for authorized users
   - `app/views/days/toggle_draft.turbo_stream.haml` - Turbo Stream response to replace the badge

4. **Feature Specs** (3 new tests in `spec/features/day_spec.rb`):
   - Admin can toggle draft status from trip page (both directions)
   - User can toggle their own day's draft status
   - User cannot toggle other users' days (no button shown)

### Responsive Day Labels
Implemented responsive day labels to handle narrow mobile screens where "Day 1" through "Day 5" plus navigation arrows are too wide:

1. **Solution**: Uses Bootstrap responsive classes to show "D1" on mobile (< 768px) and "Day 1" on desktop (≥ 768px)

2. **Implementation**:
   - Created `day_label(day, long: true/false)` helper method with locale support (`day.label` and `day.short.label`)
   - Home page renders both forms with `.d-md-none` (mobile) and `.d-none.d-md-inline` (desktop) classes
   - Breakpoint chosen: md (768px) covers both xs and sm devices

3. **Benefits**: Best of both worlds - compact labels on mobile, friendly labels on desktop, no functionality loss

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
- [x] Write feature specs for days (19 tests, all passing)
- [x] Test CRUD operations for admins, users, and guests ✓
- [x] Test date validations (day within trip range) ✓
- [x] Test trip date change prevention when it would orphan days ✓
- [x] Test slot availability and default date assignment ✓
- [x] Test draft status handling ✓
- [x] Add inline draft toggle with Turbo Stream ✓

### Phase 5: Active Storage & Media
- [x] Install Active Storage (migrations created)
- [x] Configure local storage (disk service)
- [x] Create Image model (belongs_to :user, has_one_attached :file)
- [x] Add image upload functionality with processing:
  - Automatic resize (max 1000px dimension, fallback to 500px if needed)
  - Compression (target under 3MB, fallback quality 70% if needed)
  - EXIF extraction (GPS coordinates from ifd0/ifd3, date taken)
  - Format preservation (JPEG stays JPEG, PNG stays PNG, WebP stays WebP)
- [x] Configure accepted formats (JPEG, PNG, WebP only - no HEIC/HEIF/GIF)
- [x] Add server-side validation (file type, size limits)
- [x] Add client-side file picker filtering (accept attribute)
- [x] Create ImagesController with authorization
- [x] Build Image views (index, show, new, edit, form partial)
- [x] Create image factory and feature specs
- [x] Verified Apple auto-converts HEIC→JPEG preserving GPS/date
- [ ] Add image embedding to day notes (Remarkable concern updates)
- [ ] Link images to specific days/trips

### Phase 6: Home Page (Viewer)
- [x] Add `ready?` method and `scope :ready` to Trip model
- [x] Create viewer layout (`layouts/viewer.html.haml`)
- [x] Build PagesController home action with trip/day selection logic
- [x] Create ViewerHelper for day window and navigation
- [x] Build home view with four parts (trip selector, day navigator, content, admin link)
- [x] Add session tracking for last viewed day per trip
- [x] Add session tracking for last admin page
- [x] Add viewer-specific CSS styling
- [x] Write feature specs (13 tests, all passing)

### Phase 7: Polish
- [x] Remove Note model and related code
- [x] Add production deployment configuration
- [x] Refactor day_label from model to helper with short form support (day_label(day, long: true/false) → "Day 1"/"D1")
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
- Active Storage (File uploads)
- ruby-vips (Image processing)
- image_processing gem (Vips wrapper)
- RSpec + Capybara (Testing)
