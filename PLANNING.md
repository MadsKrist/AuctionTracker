# PLANNING.md - AuctionTracker Strategic Planning Document

## Vision Statement

### Product Vision
Create the definitive auction house tracking solution for WoW 1.12 that empowers players to make data-driven economic decisions by providing complete visibility into their auction house activities, with seamless export capabilities for advanced external analysis.

### Core Value Propositions
1. **Complete Transaction History** - Never lose track of what sold, what didn't, and why
2. **Data-Driven Insights** - Transform raw auction data into actionable intelligence
3. **Export Flexibility** - Bridge the gap between in-game data and external analytics tools
4. **Zero Data Loss** - Reliable correlation between auctions and mail receipts
5. **Performance First** - Minimal impact on game performance even with thousands of transactions

### Long-Term Goals
- Become the standard auction tracking solution for vanilla WoW servers
- Enable community-driven market analysis through aggregated data
- Support integration with web-based visualization platforms
- Maintain compatibility across all 1.12 server implementations
- Foster an ecosystem of companion tools and analytics platforms

### Success Metrics
- 99%+ accuracy in auction-to-mail correlation
- < 5MB memory footprint for typical use
- < 1ms processing time per auction operation
- Zero data loss during unexpected disconnects
- Support for 10,000+ transaction history

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     WoW Client (1.12)                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              AuctionTracker Addon                     │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │ Event Layer  │  │ Hook Layer   │  │ UI Layer   │ │   │
│  │  │              │  │              │  │            │ │   │
│  │  │ • AH Events  │  │ • StartAuct  │  │ • Main Win │ │   │
│  │  │ • Mail Event │  │ • GetInbox   │  │ • Minimap  │ │   │
│  │  │ • System Msg │  │ • Custom API │  │ • Overlays │ │   │
│  │  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘ │   │
│  │         │                  │                 │        │   │
│  │  ┌──────▼──────────────────▼─────────────────▼──────┐ │   │
│  │  │            Core Processing Engine                 │ │   │
│  │  ├────────────────────────────────────────────────────┤ │   │
│  │  │ • Auction Capture    • Mail Correlation          │ │   │
│  │  │ • ID Generation      • Fuzzy Matching            │ │   │
│  │  │ • State Management   • Transaction Processing    │ │   │
│  │  └──────────────────────┬────────────────────────────┘ │   │
│  │                          │                            │   │
│  │  ┌───────────────────────▼────────────────────────────┐ │   │
│  │  │              Data Management Layer                 │ │   │
│  │  ├─────────────────────────────────────────────────────┤ │   │
│  │  │ • SavedVariables I/O  • Data Validation           │ │   │
│  │  │ • History Management  • Statistics Calculation    │ │   │
│  │  │ • Export Generation   • Memory Optimization       │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  │                                                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              ▼                               │
│                    ┌──────────────────┐                      │
│                    │  SavedVariables  │                      │
│                    │   (Persistent)   │                      │
│                    └──────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │  External Tools  │
                    │  (Future: Web    │
                    │   Visualization) │
                    └──────────────────┘
```

### Component Architecture

#### 1. Event System
- **Purpose**: Capture game events and route to appropriate handlers
- **Key Events**: Auction house, mailbox, system messages
- **Design Pattern**: Observer pattern with centralized dispatcher
- **Performance**: Event filtering to minimize unnecessary processing

#### 2. Hook System
- **Purpose**: Intercept and monitor API calls without breaking other addons
- **Implementation**: Pre-hook pattern (store original, call custom, call original)
- **Safety**: Non-destructive hooks that preserve original functionality
- **Compatibility**: Coexistence with other auction addons

#### 3. Correlation Engine
- **Purpose**: Match mail receipts to pending auctions
- **Algorithm**: Multi-stage matching (exact → fuzzy → probabilistic)
- **Accuracy**: Confidence scoring system for uncertain matches
- **Flexibility**: Configurable matching thresholds

#### 4. Data Layer
- **Purpose**: Manage persistent storage and data operations
- **Structure**: Hierarchical (Realm → Character → Auctions)
- **Optimization**: Automatic pruning and compression
- **Integrity**: Version control and migration support

#### 5. UI System
- **Purpose**: Present data and enable user interaction
- **Framework**: XML templates with Lua handlers
- **Components**: Modular, reusable UI elements
- **Responsiveness**: Asynchronous updates to prevent freezing

### Data Flow Architecture

```
Auction Posted → Capture Data → Generate ID → Store Pending
                                                    ↓
Mail Received → Parse Content → Correlation → Update Status
                                                    ↓
                              History → Statistics → Export
```

### Memory Management Strategy

1. **Active Memory** (< 2MB)
   - Current session auctions
   - Active UI elements
   - Processing buffers

2. **Cached Memory** (< 3MB)
   - Recent history (7 days)
   - Calculated statistics
   - Search indices

3. **Persistent Storage** (< 10MB)
   - Full history (30 days default)
   - Configuration
   - Realm-wide data

## Technology Stack

### Core Technologies

#### Language & Runtime
- **Lua 5.0** - WoW 1.12's embedded scripting language
  - No modern Lua features (5.1+)
  - Limited standard library
  - Custom WoW extensions

#### WoW API Version
- **Interface Version**: 11200
- **API Level**: Vanilla 1.12.1
- **Limitations**: No secure templates, basic frame API

#### UI Framework
- **XML Templates** - Frame definitions and layouts
- **Lua Handlers** - Event processing and logic
- **Blizzard Widgets** - Native UI components
  - Frame, Button, EditBox, ScrollFrame
  - GameTooltip, DropDownMenu
  - StatusBar, Texture, FontString

### Data Technologies

#### Storage
- **SavedVariables** - Persistent storage system
  - Format: Lua table serialization
  - Location: `WTF/Account/[ACCOUNT]/SavedVariables/`
  - Per-character: `WTF/Account/[ACCOUNT]/[REALM]/[CHARACTER]/SavedVariables/`
  - Limitations: No binary data, size constraints

#### Serialization
- **CSV Export** - Via string generation
- **JSON Export** - Manual table serialization
- **Lua Tables** - Native format for SavedVariables

### Libraries & Dependencies

#### Core Dependencies
- **None** - Fully self-contained by design

#### Optional Libraries
- **Ace2** (if available) - Enhanced UI framework
  - AceAddon-2.0 - Addon framework
  - AceDB-2.0 - Database management
  - AceEvent-2.0 - Event handling

- **LibStub** - Library versioning (if using libs)
- **LibDataBroker** - Data feed for display addons

### Development Patterns

#### Design Patterns Used
1. **Module Pattern** - Encapsulated components
2. **Observer Pattern** - Event system
3. **Factory Pattern** - Auction record creation
4. **Strategy Pattern** - Correlation algorithms
5. **Facade Pattern** - Simplified API surface

#### Code Organization
```lua
-- Namespace pattern
AuctionTracker = AuctionTracker or {}
AuctionTracker.Modules = {}

-- Module pattern
AuctionTracker.Modules.MailProcessor = {}
function AuctionTracker.Modules.MailProcessor:Initialize()
    -- Module initialization
end

-- Mixin pattern for shared functionality
AuctionTracker.Mixins = {}
function AuctionTracker.Mixins:InheritFrom(target)
    -- Inherit methods
end
```

## Required Tools

### Development Environment

#### Essential Tools

1. **Text Editor / IDE**
   - **Recommended**: Visual Studio Code
     - Extensions: Lua, WoW API
   - **Alternative**: Sublime Text, Notepad++
   - **Features Needed**: Syntax highlighting, Lua support

2. **WoW 1.12 Client**
   - **Version**: 1.12.1 (5875)
   - **Purpose**: Testing environment
   - **Configuration**: Enable Lua errors (`/console scriptErrors 1`)

3. **Version Control**
   - **System**: Git
   - **Repository**: GitHub/GitLab
   - **Structure**: Semantic versioning (v1.0.0)

#### Development Addons

1. **DevTools** (1.12 compatible)
   - Frame inspector
   - Event monitor
   - API browser

2. **BugSack + BugGrabber**
   - Error capture
   - Error history
   - Stack traces

3. **WoWLua** (if available for 1.12)
   - In-game Lua console
   - Quick testing
   - API exploration

### Testing Tools

#### In-Game Testing
1. **Multiple Characters**
   - Different factions (Horde/Alliance)
   - Various levels
   - Different servers/realms

2. **Auction House Access**
   - Major cities (Org/IF)
   - Neutral AH (Gadgetzan/Booty Bay)

3. **Test Items**
   - Various item types
   - Different stack sizes
   - Range of values

#### Data Testing
1. **SavedVariables Editor**
   - Manual data inspection
   - Corruption testing
   - Migration testing

2. **Memory Profiler**
   - Custom memory tracking
   - Garbage collection monitoring
   - Leak detection

### Documentation Tools

1. **Markdown Editor**
   - For README, CHANGELOG
   - Documentation maintenance

2. **LuaDoc** (optional)
   - API documentation generation
   - Comment parsing

3. **Diagramming Tool**
   - Architecture diagrams
   - Data flow visualization
   - draw.io or similar

### Build & Release Tools

#### Packaging
1. **ZIP Creation**
   - Exclude development files
   - Include only necessary files
   - Maintain folder structure

2. **Version Management**
   - TOC version updates
   - Changelog generation
   - Tag creation

#### Distribution Preparation
```bash
# Release structure
AuctionTracker/
├── AuctionTracker.toc
├── *.lua files
├── Locale/*.lua
└── README.md

# Exclude from release
.git/
.gitignore
*.md (except README)
test/
dev/
```

### External Tools (Future Integration)

#### Data Visualization
1. **Web Stack** (for external viewer)
   - HTML/CSS/JavaScript
   - Chart.js or D3.js
   - CSV parsing library

2. **Database** (optional)
   - SQLite for local storage
   - PostgreSQL for aggregated data
   - Time-series DB for market trends

#### Analytics Platform
1. **Data Processing**
   - Python with pandas
   - R for statistical analysis
   - Excel for quick analysis

2. **API Development** (future)
   - REST API for data upload
   - WebSocket for real-time updates
   - Authentication system

## Development Workflow

### Phase 1: Local Development
1. Edit code in VS Code
2. Reload UI in-game (`/reload`)
3. Test functionality
4. Check SavedVariables
5. Monitor errors with BugSack

### Phase 2: Testing
1. Create test scenarios
2. Execute test plan
3. Verify data accuracy
4. Check memory usage
5. Test edge cases

### Phase 3: Release
1. Update version numbers
2. Update changelog
3. Create git tag
4. Package addon
5. Upload to distribution sites

### Debugging Workflow
```lua
-- Debug flag in Core.lua
AuctionTracker.DEBUG = true

-- Debug function
function AuctionTracker:Debug(...)
    if self.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AT Debug]:|r " .. string.format(...))
    end
end

-- Usage
self:Debug("Auction captured: %s x%d", itemName, quantity)
```

## Risk Mitigation

### Technical Risks
1. **API Changes** - Server variations may have different APIs
   - Mitigation: Defensive programming, fallbacks

2. **Memory Limitations** - Large datasets may cause issues
   - Mitigation: Aggressive pruning, data compression

3. **Addon Conflicts** - Other addons may interfere
   - Mitigation: Namespace isolation, safe hooking

4. **Data Corruption** - SavedVariables may become corrupted
   - Mitigation: Validation, backup system

### User Experience Risks
1. **Learning Curve** - Complex features may confuse users
   - Mitigation: Progressive disclosure, good defaults

2. **Performance Impact** - May affect game performance
   - Mitigation: Optimization, optional features

3. **Data Loss** - Users may lose transaction history
   - Mitigation: Export reminders, backup system

## Success Criteria

### Technical Success
- ✅ < 5ms processing time per operation
- ✅ < 5MB memory usage (typical)
- ✅ 99%+ correlation accuracy
- ✅ Zero critical errors
- ✅ Compatible with major addons

### User Success
- ✅ Intuitive interface
- ✅ Reliable data tracking
- ✅ Useful insights generated
- ✅ Smooth export process
- ✅ Active community adoption

### Project Success
- ✅ Regular updates
- ✅ Community contributions
- ✅ Documentation complete
- ✅ Support resources available
- ✅ Integration ecosystem developing