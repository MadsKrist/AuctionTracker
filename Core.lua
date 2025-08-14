-- Core.lua - Main initialization and event handling for AuctionTracker
-- World of Warcraft 1.12 Vanilla Addon

-- Create main addon namespace
AuctionTracker = AuctionTracker or {}

-- Addon information
AuctionTracker.VERSION = "1.0.0"
AuctionTracker.DEBUG = false

-- Create main frame for event handling
local frame = CreateFrame("Frame", "AuctionTrackerFrame")
AuctionTracker.frame = frame

-- Event registration and handler
local events = {
    "VARIABLES_LOADED",
    "PLAYER_LOGIN",
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
    "CHAT_MSG_SYSTEM",
    "MAIL_SHOW",
    "MAIL_CLOSED",
    "MAIL_INBOX_UPDATE"
}

-- Initialize event registration
function AuctionTracker:RegisterEvents()
    for _, event in pairs(events) do
        frame:RegisterEvent(event)
    end
end

-- Main event handler
function AuctionTracker:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    if event == "VARIABLES_LOADED" then
        self:InitializeDatabase()
    elseif event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "AUCTION_HOUSE_SHOW" then
        self:OnAuctionHouseShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self:OnAuctionHouseClosed()
    elseif event == "CHAT_MSG_SYSTEM" then
        self:OnSystemMessage(arg1)
    elseif event == "MAIL_SHOW" then
        self:OnMailShow()
    elseif event == "MAIL_CLOSED" then
        self:OnMailClosed()
    elseif event == "MAIL_INBOX_UPDATE" then
        self:OnMailInboxUpdate()
    end
end

-- Initialize the database structure
function AuctionTracker:InitializeDatabase()
    -- Create global saved variables if they don't exist
    if not AuctionTrackerDB then
        AuctionTrackerDB = {
            version = self.VERSION,
            realm = {}
        }
    end
    
    -- Create character-specific saved variables
    if not AuctionTrackerCharDB then
        AuctionTrackerCharDB = {
            version = self.VERSION,
            settings = {
                historyDays = 30,
                autoClean = true,
                debugMode = false
            }
        }
    end
    
    -- Check for version updates and migrate if needed
    self:CheckVersion()
    
    -- Initialize realm/character structure
    self:InitializeCharacterData()
end

-- Check database version and migrate if needed
function AuctionTracker:CheckVersion()
    if not AuctionTrackerDB.version or AuctionTrackerDB.version ~= self.VERSION then
        self:MigrateDatabase(AuctionTrackerDB.version or "0.0.0", self.VERSION)
        AuctionTrackerDB.version = self.VERSION
    end
    
    if not AuctionTrackerCharDB.version or AuctionTrackerCharDB.version ~= self.VERSION then
        AuctionTrackerCharDB.version = self.VERSION
    end
end

-- Initialize character-specific data structure
function AuctionTracker:InitializeCharacterData()
    local realmName = GetRealmName()
    local playerName = UnitName("player")
    
    if not realmName or not playerName then
        -- Data not available yet, will retry on PLAYER_LOGIN
        return
    end
    
    -- Initialize realm table if needed
    if not AuctionTrackerDB.realm[realmName] then
        AuctionTrackerDB.realm[realmName] = {}
    end
    
    -- Initialize character data if needed
    if not AuctionTrackerDB.realm[realmName][playerName] then
        AuctionTrackerDB.realm[realmName][playerName] = {
            auctions = {
                active = {},
                history = {}
            },
            statistics = {
                totalPosted = 0,
                totalSold = 0,
                totalExpired = 0,
                totalRevenue = 0,
                totalDeposits = 0,
                lastUpdated = time()
            }
        }
    end
    
    self.currentRealm = realmName
    self.currentPlayer = playerName
    self.playerData = AuctionTrackerDB.realm[realmName][playerName]
end

-- Database migration function
function AuctionTracker:MigrateDatabase(oldVersion, newVersion)
    self:Debug("Migrating database from %s to %s", oldVersion, newVersion)
    -- Migration logic will be added as needed for future versions
end

-- Player login handler
function AuctionTracker:OnPlayerLogin()
    -- Ensure character data is initialized now that we have all info
    self:InitializeCharacterData()
    
    -- Clean old data if auto-clean is enabled
    if AuctionTrackerCharDB.settings.autoClean then
        self:CleanOldData()
    end
    
    -- Set debug mode from character settings
    self.DEBUG = AuctionTrackerCharDB.settings.debugMode
    
    self:Debug("AuctionTracker loaded for %s on %s", self.currentPlayer, self.currentRealm)
end

-- Auction house opened
function AuctionTracker:OnAuctionHouseShow()
    self:Debug("Auction House opened")
    -- TODO: Set up auction house hooks
end

-- Auction house closed
function AuctionTracker:OnAuctionHouseClosed()
    self:Debug("Auction House closed")
    -- TODO: Clean up any temporary data
end

-- System message handler (for "Auction created" messages)
function AuctionTracker:OnSystemMessage(message)
    -- TODO: Parse auction creation confirmations
    if message and string.find(message, "Auction created") then
        self:Debug("Auction creation detected: %s", message)
    end
end

-- Mail window opened
function AuctionTracker:OnMailShow()
    self:Debug("Mail window opened")
    -- TODO: Scan inbox for auction results
end

-- Mail window closed
function AuctionTracker:OnMailClosed()
    self:Debug("Mail window closed")
end

-- Mail inbox updated
function AuctionTracker:OnMailInboxUpdate()
    self:Debug("Mail inbox updated")
    -- TODO: Process new mail for auction results
end

-- Clean old auction history data
function AuctionTracker:CleanOldData()
    if not self.playerData then
        return
    end
    
    local cutoffTime = time() - (AuctionTrackerCharDB.settings.historyDays * 24 * 3600)
    local cleaned = 0
    
    -- Clean history table
    for auctionId, auction in pairs(self.playerData.auctions.history) do
        if auction.postTime and auction.postTime < cutoffTime then
            self.playerData.auctions.history[auctionId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        self:Debug("Cleaned %d old auction records", cleaned)
    end
end

-- Debug message function
function AuctionTracker:Debug(...)
    if self.DEBUG then
        local message = string.format(...)
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AuctionTracker Debug]:|r " .. message)
    end
end

-- Utility function to get current timestamp
function AuctionTracker:GetTimestamp()
    return time()
end

-- Utility function to format money (copper to gold/silver/copper)
function AuctionTracker:FormatMoney(copper)
    if not copper or copper == 0 then
        return "0c"
    end
    
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperRemainder = copper % 100
    
    local result = ""
    if gold > 0 then
        result = result .. gold .. "g"
    end
    if silver > 0 then
        result = result .. silver .. "s"
    end
    if copperRemainder > 0 or result == "" then
        result = result .. copperRemainder .. "c"
    end
    
    return result
end

-- Set up the event handler
frame:SetScript("OnEvent", function()
    AuctionTracker:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
end)

-- Register all events
AuctionTracker:RegisterEvents()

-- Slash commands
SLASH_AUCTIONTRACKER1 = "/at"
SLASH_AUCTIONTRACKER2 = "/auctiontracker"

function SlashCmdList.AUCTIONTRACKER(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end
    
    local command = args[1] or "help"
    
    if command == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AuctionTracker Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/at debug - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("/at clean - Clean old data")
        DEFAULT_CHAT_FRAME:AddMessage("/at stats - Show statistics")
        DEFAULT_CHAT_FRAME:AddMessage("/at version - Show version")
    elseif command == "debug" then
        AuctionTracker.DEBUG = not AuctionTracker.DEBUG
        AuctionTrackerCharDB.settings.debugMode = AuctionTracker.DEBUG
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AuctionTracker:|r Debug mode " .. (AuctionTracker.DEBUG and "enabled" or "disabled"))
    elseif command == "clean" then
        AuctionTracker:CleanOldData()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AuctionTracker:|r Old data cleaned")
    elseif command == "stats" then
        if AuctionTracker.playerData then
            local stats = AuctionTracker.playerData.statistics
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AuctionTracker Statistics:|r")
            DEFAULT_CHAT_FRAME:AddMessage("Posted: " .. stats.totalPosted .. " | Sold: " .. stats.totalSold .. " | Expired: " .. stats.totalExpired)
            DEFAULT_CHAT_FRAME:AddMessage("Revenue: " .. AuctionTracker:FormatMoney(stats.totalRevenue) .. " | Deposits: " .. AuctionTracker:FormatMoney(stats.totalDeposits))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AuctionTracker:|r No data available")
        end
    elseif command == "version" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AuctionTracker:|r Version " .. AuctionTracker.VERSION)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AuctionTracker:|r Unknown command. Use /at help for commands.")
    end
end