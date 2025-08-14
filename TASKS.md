# TASKS.md - AuctionTracker Development Milestones

## Milestone 1: Foundation & Basic Tracking
**Goal**: Set up addon structure and capture auction posting data

### Setup Tasks
- [x] Write initial TOC file with metadata
- [x] Create `Core.lua` with basic frame and event registration
- [x] Set up SavedVariables initialization
- [x] Implement database versioning system
- [x] Create realm/character data structure

### Auction Capture Tasks
- [ ] Hook `StartAuction()` function
- [ ] Capture auction data from `GetAuctionSellItemInfo()`
- [ ] Parse `CHAT_MSG_SYSTEM` for "Auction created" confirmation
- [ ] Generate unique auction IDs (timestamp + itemId + random)
- [ ] Store pending auctions in active table
- [ ] Handle auction house open/close events
- [ ] Track deposit costs from UI elements

### Data Validation
- [ ] Validate captured item data (nil checks)
- [ ] Handle special characters in item names
- [ ] Test with gray/white/green/blue/epic items
- [ ] Verify stack size detection
- [ ] Test with trade goods vs equipment

## Milestone 2: Mail Processing & Correlation
**Goal**: Detect sales and returns through mailbox monitoring

### Mail Detection Tasks
- [ ] Register mail-related events (`MAIL_SHOW`, `MAIL_INBOX_UPDATE`)
- [ ] Identify Auction House sender mails
- [ ] Parse `GetInboxHeaderInfo()` for all mail items
- [ ] Detect sold auctions (money only, no items)
- [ ] Detect expired auctions (items returned, no money)
- [ ] Detect cancelled auctions (items with deposit refund)
- [ ] Handle partial stack sales

### Correlation Engine
- [ ] Implement exact match algorithm (itemId + quantity + time)
- [ ] Add fuzzy matching for edge cases
- [ ] Handle multiple identical pending auctions
- [ ] Create confidence scoring system
- [ ] Match successful sales to original prices
- [ ] Extract buyer names from `GetInboxInvoiceInfo()`
- [ ] Update auction status (pending → sold/expired)

### Edge Cases
- [ ] Handle full mailbox (50+ items)
- [ ] Process COD mails correctly (ignore)
- [ ] Detect auction cancellations vs expires
- [ ] Handle multi-page mail inbox
- [ ] Test with neutral auction house

## Milestone 3: Data Management & Persistence
**Goal**: Robust data storage and history management

### Storage Tasks
- [ ] Move completed auctions from active to history
- [ ] Implement data cleanup (30-day default)
- [ ] Add configurable history retention period
- [ ] Calculate profit/loss per transaction
- [ ] Track running statistics (total sold, expired, revenue)
- [ ] Implement data migration for version updates
- [ ] Add backup/restore functionality

### Performance Optimization
- [ ] Batch process mail scanning
- [ ] Defer processing during combat
- [ ] Implement operation queuing system
- [ ] Add memory usage monitoring
- [ ] Optimize table operations for large datasets
- [ ] Add data compression for old records
- [ ] Implement table recycling

### Data Integrity
- [ ] Add data validation on load
- [ ] Handle corrupted SavedVariables
- [ ] Implement error recovery
- [ ] Add debug logging system
- [ ] Create data consistency checks
- [ ] Test with 1000+ transactions

## Milestone 4: User Interface
**Goal**: Create intuitive UI for viewing and managing auction data

### Main Window
- [ ] Create main frame with tabs
- [ ] Implement "Active Auctions" tab with sortable columns
- [ ] Build "History" tab with pagination
- [ ] Add "Statistics" tab with summary data
- [ ] Create "Settings" tab for configuration
- [ ] Add close button and draggable frame
- [ ] Implement window position saving

### Active Auctions View
- [ ] Display pending auctions in table format
- [ ] Show time remaining for each auction
- [ ] Color-code by duration (2h/8h/24h)
- [ ] Add sorting by column headers
- [ ] Include calculated potential profit
- [ ] Show total value and deposit costs
- [ ] Add refresh button

### History View
- [ ] Create scrollable transaction list
- [ ] Implement search by item name
- [ ] Add date range filter
- [ ] Create status filter (sold/expired/all)
- [ ] Show profit/loss per item
- [ ] Add sorting capabilities
- [ ] Implement pagination for large datasets

### Statistics Panel
- [ ] Display total items posted/sold/expired
- [ ] Calculate success rate percentage
- [ ] Show total revenue and deposits
- [ ] Display average profit margin
- [ ] Add time period selector
- [ ] Create top selling items list
- [ ] Show best profit margins

### Additional UI Elements
- [ ] Create minimap button
- [ ] Add tooltip with quick stats
- [ ] Implement right-click context menu
- [ ] Add slash commands (`/at`, `/auctiontracker`)
- [ ] Create auction house overlay
- [ ] Add item history tooltip enhancement

## Milestone 5: Export & Analytics
**Goal**: Enable data export and advanced analytics

### Export Implementation
- [ ] Create CSV string generation function
- [ ] Build export dialog with scrollable EditBox
- [ ] Add "Select All" functionality
- [ ] Implement date range selection for export
- [ ] Add field selection options
- [ ] Create export templates (simple/detailed)
- [ ] Handle special characters in CSV

### Export Features
- [ ] Export active auctions
- [ ] Export transaction history
- [ ] Export summary statistics
- [ ] Include realm and character info
- [ ] Add timestamp formatting options
- [ ] Create JSON export option
- [ ] Implement chunked export for large data

### Analytics
- [ ] Calculate profit margins per item type
- [ ] Track price trends over time
- [ ] Identify best selling days/times
- [ ] Generate monthly summary reports
- [ ] Calculate deposit cost efficiency
- [ ] Track success rate by item category
- [ ] Identify optimal pricing strategies

## Milestone 6: Polish & Optimization
**Goal**: Refine user experience and ensure stability

### Bug Fixes & Stability
- [ ] Fix mail correlation edge cases
- [ ] Handle addon conflicts (Auctioneer, TSM, Postal)
- [ ] Resolve memory leaks
- [ ] Fix UI scaling issues
- [ ] Handle special characters properly
- [ ] Test with non-English clients
- [ ] Fix timezone handling

### User Experience
- [ ] Add confirmation dialogs for data cleanup
- [ ] Implement undo for recent actions
- [ ] Add keyboard shortcuts
- [ ] Create help documentation
- [ ] Add tooltips for all UI elements
- [ ] Implement color customization
- [ ] Add sound notifications option

### Localization
- [ ] Extract all strings to locale files
- [ ] Create enUS locale base
- [ ] Prepare framework for translations
- [ ] Handle number formatting by locale
- [ ] Test with different client languages
- [ ] Add locale-specific date formats

### Performance Tuning
- [ ] Profile addon CPU usage
- [ ] Optimize event handler efficiency
- [ ] Reduce garbage collection impact
- [ ] Implement lazy loading for UI
- [ ] Optimize SavedVariables size
- [ ] Add performance monitoring options
- [ ] Create lite mode for low-end systems

### Documentation
- [ ] Write user guide
- [ ] Create FAQ section
- [ ] Document API for other addons
- [ ] Add code comments
- [ ] Create troubleshooting guide
- [ ] Write developer documentation

## Milestone 7: Advanced Features (Optional)
**Goal**: Add power-user features and integrations

### Advanced Tracking
- [ ] Track competitor pricing
- [ ] Monitor market trends
- [ ] Add item watchlists
- [ ] Create price alerts
- [ ] Track cross-faction arbitrage
- [ ] Monitor seasonal price changes

### Integration Features
- [ ] Add API for other addons
- [ ] Create LibDataBroker plugin
- [ ] Integrate with popular auction addons
- [ ] Add FuBar/Titan Panel support
- [ ] Create data sharing between alts
- [ ] Implement guild data sharing

### Automation Helpers
- [ ] Add quick-post from history
- [ ] Create pricing suggestions
- [ ] Implement batch operations
- [ ] Add auction templates
- [ ] Create restock reminders
- [ ] Track inventory levels

## Testing Checklist
**To be performed after each milestone**

### Functional Testing
- [ ] Post single item auction
- [ ] Post stack auction
- [ ] Post multiple identical auctions
- [ ] Receive sold auction mail
- [ ] Receive expired auction mail
- [ ] Cancel active auction
- [ ] Test with full mailbox
- [ ] Test with empty auction data
- [ ] Verify profit calculations
- [ ] Test export functionality

### Compatibility Testing
- [ ] Test with Auctioneer addon
- [ ] Test with Postal addon
- [ ] Test with TSM (if backported)
- [ ] Test on different realms
- [ ] Test with multiple characters
- [ ] Test Horde and Alliance
- [ ] Test neutral auction house

### Performance Testing
- [ ] Monitor memory usage over time
- [ ] Test with 100+ active auctions
- [ ] Test with 1000+ history records
- [ ] Measure frame rate impact
- [ ] Test export of large datasets
- [ ] Monitor CPU usage during operations

## Notes

### Priority Order
1. **Critical**: Milestones 1-2 (Core functionality)
2. **High**: Milestones 3-4 (Data & UI)
3. **Medium**: Milestone 5 (Export)
4. **Low**: Milestones 6-7 (Polish & Advanced)

### Development Tips
- Test each milestone thoroughly before moving on
- Keep SavedVariables under 10MB for performance
- Always test with both factions
- Consider backward compatibility for data structure changes
- Profile performance after each major feature

### Success Criteria
- ✅ Accurately tracks 99% of auctions
- ✅ Successfully correlates mail to auctions
- ✅ Exports data without errors
- ✅ UI is responsive and intuitive
- ✅ No performance impact during gameplay
- ✅ Compatible with major auction addons