# CLAUDE.md - WoW Auction Tracker Addon Development Guide

## Session Instructions
**At the start of every new conversation:**
1. Always read `PLANNING.md` first to understand the vision and architecture
2. Check `TASKS.md` to review current progress and identify next tasks
3. Mark completed tasks immediately when work is finished
4. Add newly discovered tasks or subtasks to appropriate milestones
5. Maintain task list accuracy throughout the session

## Project Overview
**Name**: AuctionTracker  
**Platform**: World of Warcraft 1.12 (Vanilla)  
**Purpose**: Track auction house transactions by correlating auction postings with mailbox receipts  
**Language**: Lua  
**Output**: SavedVariables with CSV export capability  

## Core Technical Requirements

### Primary Functionality
1. Detect and record auction postings via AuctionHouse API hooks
2. Monitor mailbox for auction results (sold/expired items)
3. Correlate mail receipts with pending auctions
4. Store transaction history in SavedVariables
5. Provide CSV export for external visualization

### WoW 1.12 API Constraints
- No native auction IDs (must generate custom IDs)
- No direct file I/O (export via copyable text)
- No auction history API (must track manually)
- Limited to SavedVariables for persistence
- Manual correlation required between AH and mail

## Implementation Details

### File Structure
```
AuctionTracker/
├── AuctionTracker.toc     # Addon manifest
├── Core.lua               # Main initialization and event handling
├── AuctionHooks.lua       # Auction house API hooks
├── MailProcessor.lua      # Mailbox scanning and correlation
├── DataManager.lua        # SavedVariables management
├── Export.lua             # CSV export functionality
├── GUI.lua                # User interface
└── Locale/
    └── enUS.lua          # Localization strings
```

### Critical API Hooks

#### Auction House
```lua
-- Events to register
"AUCTION_HOUSE_SHOW"
"AUCTION_HOUSE_CLOSED"
"CHAT_MSG_SYSTEM"        -- For "Auction created" messages
"NEW_AUCTION_UPDATE"

-- Functions to hook
StartAuction(minBid, buyoutPrice, runTime)
GetAuctionSellItemInfo()
GetOwnerAuctionItems()

-- Data extraction
itemName, texture, quantity, quality, canUse, level, minBid, minIncrement, 
buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("owner", index)
```

#### Mailbox
```lua
-- Events to register
"MAIL_INBOX_UPDATE"
"MAIL_SHOW"
"MAIL_CLOSED"

-- Functions to use
GetInboxNumItems()
packageIcon, stationeryIcon, sender, subject, money, CODAmount, 
daysLeft, hasItem, wasRead = GetInboxHeaderInfo(index)
invoiceType, itemName, playerName, bid, buyout, deposit, 
consignment = GetInboxInvoiceInfo(index)
```

### Data Structures

#### Auction Record Schema
```lua
{
    id = "timestamp_itemId_random",  -- Generated unique ID
    itemLink = "[Item Name]",        -- Full item link
    itemName = "Item Name",
    itemId = 12345,
    quantity = 20,
    stackSize = 20,
    bidPrice = 1000,                 -- In copper
    buyoutPrice = 1500,               -- In copper
    depositCost = 50,                 -- In copper
    duration = 24,                    -- 2, 8, or 24 hours
    postTime = 1234567890,            -- Unix timestamp
    status = "pending",               -- pending|sold|expired|cancelled
    soldPrice = nil,                  -- Actual sale price if sold
    soldTime = nil,                   -- When item sold
    buyerName = nil                   -- From invoice if available
}
```

#### SavedVariables Structure
```lua
AuctionTrackerDB = {
    version = "1.0.0",
    realm = {
        ["RealmName"] = {
            ["CharacterName"] = {
                auctions = {
                    active = {},    -- Current pending auctions
                    history = {}    -- Completed transactions
                },
                statistics = {
                    totalPosted = 0,
                    totalSold = 0,
                    totalExpired = 0,
                    totalRevenue = 0,
                    totalDeposits = 0
                },
                settings = {
                    historyDays = 30,
                    autoClean = true
                }
            }
        }
    }
}
```

### Correlation Algorithm

```lua
-- Pseudo-code for matching mail to auctions
function MatchMailToAuction(mailData)
    -- 1. Check if mail is from "Auction House"
    if sender ~= "Auction House" then return end
    
    -- 2. Determine mail type
    if mailData.money > 0 and not mailData.hasItem then
        -- SOLD: Money only = successful sale
        status = "sold"
    elseif mailData.hasItem and mailData.money == 0 then
        -- EXPIRED: Items returned, no money
        status = "expired"
    elseif mailData.hasItem and mailData.money > 0 then
        -- PARTIAL: Some stacks sold, some returned
        status = "partial"
    end
    
    -- 3. Find matching auction
    -- Match by: itemId + quantity + timeWindow
    for id, auction in pairs(active_auctions) do
        if auction.itemId == mailData.itemId and
           auction.quantity == mailData.quantity and
           auction.postTime < currentTime and
           auction.status == "pending" then
            -- Found match
            return auction
        end
    end
    
    -- 4. Fallback: fuzzy matching
    -- Consider partial matches, similar quantities, etc.
end
```

### Export Format
```csv
timestamp,item_name,item_id,quantity,stack_size,bid_price,buyout_price,status,sold_price,deposit_cost,profit,duration,realm,character
1234567890,"Copper Ore",2770,20,20,1000,1500,"sold",1500,50,1450,24,"RealmName","CharName"
```

## Development Guidelines

### Event Handling Pattern
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:SetScript("OnEvent", function()
    if event == "AUCTION_HOUSE_SHOW" then
        -- Handle auction house opened
    end
end)
```

### Hook Implementation
```lua
-- Safe hooking pattern for 1.12
local original_StartAuction = StartAuction
StartAuction = function(minBid, buyoutPrice, runTime)
    -- Capture auction data before calling original
    local name, texture, count, quality, canUse, price = GetAuctionSellItemInfo()
    
    -- Store pending auction
    StorePendingAuction(name, count, minBid, buyoutPrice, runTime)
    
    -- Call original function
    return original_StartAuction(minBid, buyoutPrice, runTime)
end
```

### Memory Management
- Limit history to 30 days by default
- Prune old records on login
- Keep active auction list minimal
- Batch process mail scanning
- Use table recycling for temporary data

### Performance Considerations
```lua
-- Defer non-critical operations
if InCombatLockdown() then
    -- Queue for later processing
    table.insert(pendingOperations, operation)
    return
end

-- Batch process queued operations
local BATCH_SIZE = 10
local processed = 0
for i, operation in ipairs(pendingOperations) do
    operation()
    processed = processed + 1
    if processed >= BATCH_SIZE then
        -- Yield to prevent freezing
        AuctionTracker:ScheduleTimer(ProcessNextBatch, 0.1)
        break
    end
end
```

## Testing Checklist

### Core Functionality
- [ ] Single item auction tracking
- [ ] Stack auction tracking (full sale)
- [ ] Stack auction tracking (partial sale)
- [ ] Expired auction detection
- [ ] Multiple identical auctions
- [ ] Deposit cost tracking
- [ ] Profit calculation

### Edge Cases
- [ ] Mailbox full (> 50 items)
- [ ] Auction cancelled detection
- [ ] Same item at different prices
- [ ] Cross-faction AH (Neutral)
- [ ] Character name changes
- [ ] Realm transfers

### Performance
- [ ] 100+ active auctions
- [ ] 1000+ history records
- [ ] Export 30 days of data
- [ ] Memory usage < 5MB
- [ ] No combat lag

## Common Issues & Solutions

### Issue: Mail correlation failures
**Solution**: Implement fuzzy matching with confidence scoring
```lua
-- Check time windows, similar quantities, recent postings
confidence = 0
if timeDiff < 48*3600 then confidence = confidence + 30 end
if quantityMatch then confidence = confidence + 40 end
if priceMatch then confidence = confidence + 30 end
```

### Issue: Duplicate auction detection
**Solution**: Generate unique IDs using multiple factors
```lua
local id = string.format("%d_%d_%d_%s", 
    time(), itemId, quantity, strlower(UnitName("player")))
```

### Issue: SavedVariables corruption
**Solution**: Implement versioning and migration
```lua
if not AuctionTrackerDB.version or AuctionTrackerDB.version < CURRENT_VERSION then
    MigrateDatabase()
end
```

## Code Snippets

### TOC File Template
```toc
## Interface: 11200
## Title: AuctionTracker
## Author: YourName
## Version: 1.0.0
## SavedVariables: AuctionTrackerDB
## SavedVariablesPerCharacter: AuctionTrackerCharDB

Core.lua
AuctionHooks.lua
MailProcessor.lua
DataManager.lua
Export.lua
GUI.lua
```

### Initialization Template
```lua
AuctionTracker = CreateFrame("Frame")
AuctionTracker:RegisterEvent("VARIABLES_LOADED")
AuctionTracker:RegisterEvent("PLAYER_LOGIN")

function AuctionTracker:OnEvent(event, ...)
    if event == "VARIABLES_LOADED" then
        self:InitializeDatabase()
    elseif event == "PLAYER_LOGIN" then
        self:SetupHooks()
        self:CleanOldData()
    end
end

AuctionTracker:SetScript("OnEvent", AuctionTracker.OnEvent)
```

## Notes for Implementation

1. **Always test with both Horde and Alliance characters** - Auction houses are faction-specific except for neutral AH

2. **Handle special characters in item names** - Use proper escaping for pattern matching

3. **Consider addon conflicts** - Test compatibility with Auctioneer, TSM backports, Postal

4. **Implement graceful degradation** - Addon should handle missing data without errors

5. **Use defensive programming** - Always check for nil values before operations

6. **Remember 1.12 limitations**:
   - No debugprofilestop()
   - No hooksecurefunc()
   - Limited string library
   - No animation system
   - Basic frame API

## Quick Reference

### Copper/Silver/Gold Conversion
```lua
-- Display format
local gold = floor(copper / 10000)
local silver = floor((copper % 10000) / 100)
local copper_remainder = copper % 100
```

### Time Handling
```lua
-- 1.12 uses time() for Unix timestamp
local currentTime = time()

-- Auction duration in seconds
local durations = {
    [1] = 2 * 3600,   -- 2 hours
    [2] = 8 * 3600,   -- 8 hours
    [3] = 24 * 3600   -- 24 hours
}
```

### Item Link Parsing
```lua
-- Extract itemId from itemLink
local _, _, itemId = string.find(itemLink, "item:(%d+):")
```

This guide should be consulted for all development work on the AuctionTracker addon. Focus on reliability, performance, and accurate data tracking within WoW 1.12's constraints.