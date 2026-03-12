# Storytime Video Library — Catalog, Discovery & Book Details Spec
> **Goal:** Upgrade the parent-facing catalog experience from basic text search to a filterable, paginated, browse-friendly interface with book detail views. Also surface age-appropriate filtering and discovery features to help parents find the right content for their children.
> **Constraint:** All catalog and discovery features are Parent Mode only. Child Mode library view is unaffected (remains a simple grid of assigned books).

---

## 0) Current State

The existing catalog (`ParentCatalogSearchView`) provides:
- Text search field + "Search" button
- Calls `GET /api/v1/catalog/books?q=...`
- Displays results as a flat list (title + author + "Add to Child Library" button)
- No filters exposed in UI (API already supports `age` and `publisher` params)
- No pagination in UI (API returns paginated results but UI shows first 20 only)
- No book detail view (description, age range, publisher info not displayed)
- No categories, tags, or browsing by collection

---

## 1) Backend Changes

### 1.1 New model: Category
**Category**
- id
- name (string, unique, not null)
- slug (string, unique, not null) — URL-safe lowercase identifier
- display_order (integer, default: 0)
- icon_name (string, nullable) — SF Symbol name for iOS display
- created_at, updated_at

**BookCategory** (join table)
- id
- book_id (foreign key)
- category_id (foreign key)
- created_at

Unique index: `(book_id, category_id)`

### 1.2 Seed categories (initial set)
- Bedtime Stories
- Adventure
- Animals & Nature
- Fairy Tales
- Learning & ABCs
- Rhymes & Songs
- Family & Friends
- Holidays & Seasons

### 1.3 Updated catalog endpoint
`GET /api/v1/catalog/books?q=...&age=...&publisher=...&category=...&page=...&per_page=...`
- New param: `category` (category slug or ID)
- Response includes category data per book

Updated book JSON in catalog response:
```json
{
  "id": 1,
  "title": "Goodnight Moon",
  "author": "Margaret Wise Brown",
  "description": "A classic bedtime story...",
  "age_min": 2,
  "age_max": 5,
  "language": "en",
  "cover_image_url": "https://...",
  "publisher": { "id": 1, "name": "HarperCollins" },
  "categories": [
    { "id": 1, "name": "Bedtime Stories", "slug": "bedtime-stories" }
  ],
  "status": "active",
  "duration_seconds": 340
}
```

### 1.4 New endpoint: list categories
`GET /api/v1/catalog/categories`
- Returns all categories ordered by `display_order`
- No auth required (public catalog metadata)
- Response:
```json
{
  "data": [
    { "id": 1, "name": "Bedtime Stories", "slug": "bedtime-stories", "icon_name": "moon.stars" }
  ]
}
```

### 1.5 New endpoint: book detail
`GET /api/v1/catalog/books/:id`
- Returns full book detail including:
  - All fields from catalog list response
  - `duration_seconds` from video_asset (if ready)
  - `has_captions` from video_asset
  - `rights_available` (boolean — is there an active rights window for this book?)
- Parent JWT required

### 1.6 Add duration to library response
`GET /api/v1/children/:child_id/library`
- Include `duration_seconds` for each book (from associated video_asset)

### 1.7 Admin console changes
- Add Category CRUD resource to ActiveAdmin
- Add category assignment to Book edit page (checkboxes or multi-select)
- Add `duration_seconds` display to Book show page (read from video_asset)

---

## 2) iOS — Catalog Filtering UI

### 2.1 Filter bar
Add a horizontal scrolling filter bar below the search field in `ParentCatalogSearchView`:

**Filter chips (horizontal scroll):**
- "All Ages" / Age picker (shows age range selector)
- Category chips (fetched from `/api/v1/catalog/categories`)
- Publisher filter (optional, phase 2)

**Age range picker:**
- Tapping the age chip presents a small popover or sheet
- Options: "All Ages", "0-2", "2-4", "4-6", "6-8", "8+"
- Maps to the `age` query parameter (sends the lower bound)

**Category chips:**
- Fetched on Parent Mode entry (cache in memory)
- Tapping a chip sets the `category` query parameter
- Active chip is visually highlighted
- Tapping again deselects (clears filter)

### 2.2 Search behavior changes
- Search triggers automatically after 300ms debounce (instead of requiring button tap)
- Clear button on search field to reset
- Empty search with active filters shows filtered browse results
- Remove the explicit "Search" button; use debounced auto-search

---

## 3) iOS — Pagination

### 3.1 Infinite scroll
Replace the current single-page list with infinite scroll:
- Load first page on search/filter change
- When user scrolls near bottom (last 3 items), fetch next page
- Show a loading indicator at the bottom while fetching
- Stop fetching when `page * per_page >= total_count`

### 3.2 ViewModel changes
Update `AppViewModel` (or create a dedicated `CatalogViewModel`):
- Track `currentPage`, `totalCount`, `isLoadingMore`, `hasMorePages`
- Method `loadNextPage()` — appends results to existing `catalogBooks` array
- Method `searchCatalog(query:)` — resets page to 1 and replaces results
- Method `applyFilter(age:category:)` — resets page to 1 and re-fetches

### 3.3 API client update
Update `APIClient.catalogBooks()` to accept all filter params:
```swift
func catalogBooks(query: String, age: Int?, category: String?, page: Int, perPage: Int) async throws -> CatalogResponseDTO
```

---

## 4) iOS — Book Detail View

### 4.1 New view: BookDetailView
Presented when parent taps a book in catalog search results (not the "Add" button):

**Layout:**
- Large cover image at top (hero style)
- Title (large, bold)
- Author (subtitle)
- Publisher name
- Age range badge: "Ages 2-5"
- Duration badge: "12 min" (from `duration_seconds`)
- Categories as horizontal pill badges
- Description (multi-line text)
- "Add to [Child Name]'s Library" button (primary action)
  - If already in library, show "Already in Library" (disabled state)

### 4.2 "Already in library" check
- Cross-reference catalog book ID against `libraryBooks` in `AppViewModel`
- Show visual indicator (checkmark badge on cover, "Already Added" text)
- Prevent duplicate adds

### 4.3 Navigation
- From `ParentCatalogSearchView`, tap book row → push `BookDetailView`
- "Add to Library" button remains on list row for quick-add without opening detail

---

## 5) iOS — Library Improvements

### 5.1 Duration display
Show video duration on book covers in both `ChildLibraryView` and `ParentLibraryManagementView`:
- Small badge in bottom-right of cover: "5:30" or "12 min"
- Only show if `duration_seconds` is available

### 5.2 Sort options (Parent Mode only)
In `ParentLibraryManagementView`, add a sort picker:
- Recently Added (default, current behavior)
- Title A-Z
- Recently Watched (uses `last_played_at` from `05_ios_player_ux.md`)

### 5.3 Empty state
When a child's library is empty:
- Show a friendly illustration placeholder
- Message: "No stories yet! Tap the button below to find some."
- "Browse Catalog" button that navigates to `ParentCatalogSearchView`

---

## 6) Data Models (iOS)

### 6.1 New model: CategoryDTO
```swift
struct CategoryDTO: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let iconName: String?
}
```

### 6.2 Updated BookDTO
Add fields:
- `categories: [CategoryDTO]` (optional, empty array default)
- `durationSeconds: Int?`
- `hasCaptions: Bool?`

### 6.3 CatalogFilterState
```swift
struct CatalogFilterState {
    var query: String = ""
    var ageRange: AgeRange? = nil
    var categorySlug: String? = nil
    var currentPage: Int = 1
    var perPage: Int = 20
}

enum AgeRange: String, CaseIterable {
    case all = "All Ages"
    case toddler = "0-2"
    case preschool = "2-4"
    case earlyReader = "4-6"
    case reader = "6-8"
    case olderReader = "8+"
}
```

---

## 7) Testing Requirements

### Backend tests
- Model test: Category uniqueness, BookCategory join
- Request test: Catalog search with category filter returns correct results
- Request test: Catalog search with age filter returns correct results
- Request test: Book detail endpoint returns full data including categories and duration
- Request test: Categories endpoint returns ordered list

### iOS tests (unit)
- CatalogViewModel: verify pagination state resets on new search
- CatalogViewModel: verify filter application triggers re-fetch
- BookDetailView: verify "Already in Library" detection

---

## 8) Deliverables for Codex (Catalog & Discovery)
Implement:
- Category model + migration + seed data
- BookCategory join table
- Updated catalog endpoint with category filter
- Categories list endpoint
- Book detail endpoint
- Admin console: Category CRUD + book category assignment
- iOS: Filter bar with age picker and category chips
- iOS: Debounced auto-search replacing button
- iOS: Infinite scroll pagination
- iOS: BookDetailView with full book info and add-to-library
- iOS: Duration badges on library covers
- iOS: Empty library state with browse prompt
