-- AuctionHooks.lua - Auction house API hooks for AuctionTracker
-- World of Warcraft 1.12 Vanilla Addon

-- Create auction hooks module
AuctionTracker.AuctionHooks = AuctionTracker.AuctionHooks or {}
local AuctionHooks = AuctionTracker.AuctionHooks

-- Store original functions
local originalStartAuction = nil
local originalGetAuctionSellItemInfo = nil

-- Track auction creation attempts
local pendingAuctionData = nil
local lastAuctionAttempt = 0

-- Initialize auction hooks
function AuctionHooks:Initialize()
    self:SetupStartAuctionHook()
    AuctionTracker:Debug("Auction hooks initialized")
end

-- Hook the StartAuction function
function AuctionHooks:SetupStartAuctionHook()
    if originalStartAuction then
        return -- Already hooked
    end
    
    -- Store original function
    originalStartAuction = StartAuction
    
    -- Create our hook
    StartAuction = function(minBid, buyoutPrice, runTime)
        -- Capture auction data before calling original
        local success = AuctionHooks:CaptureAuctionData(minBid, buyoutPrice, runTime)
        
        if success then
            AuctionTracker:Debug("Captured auction data: %s x%d, bid: %s, buyout: %s, duration: %dh", 
                pendingAuctionData.itemName or "Unknown", 
                pendingAuctionData.quantity or 0,
                AuctionTracker:FormatMoney(minBid),
                buyoutPrice > 0 and AuctionTracker:FormatMoney(buyoutPrice) or "None",
                runTime == 1 and 2 or (runTime == 2 and 8 or 24))
        end
        
        -- Call original function
        return originalStartAuction(minBid, buyoutPrice, runTime)
    end
end

-- Capture auction data from the UI
function AuctionHooks:CaptureAuctionData(minBid, buyoutPrice, runTime)
    -- Get item info from auction sell item info
    local name, texture, count, quality, canUse, price = GetAuctionSellItemInfo()
    
    if not name or not count then
        AuctionTracker:Debug("Failed to capture auction data - no item info available")
        return false
    end
    
    -- Get item link if possible (for better identification)
    local itemLink = nil
    local itemId = nil
    
    -- Try to get item link from cursor or selected item
    if CursorHasItem() then
        -- Item is on cursor, we can't easily get the link in 1.12
        -- We'll rely on name and other data for correlation
    end
    
    -- Extract item ID from texture path (fallback method for 1.12)
    if texture then
        -- Texture paths in 1.12 often contain item info we can use
        local textureStr = tostring(texture)
        -- This is a fallback - item ID extraction from texture is limited in 1.12
    end
    
    -- Calculate deposit cost (estimated based on 1.12 mechanics)
    local depositCost = self:CalculateDepositCost(minBid, buyoutPrice, runTime, count)
    
    -- Store pending auction data
    pendingAuctionData = {
        itemName = name,
        itemLink = itemLink,
        itemId = itemId, -- May be nil in 1.12
        quantity = count,
        stackSize = count,
        bidPrice = minBid,
        buyoutPrice = buyoutPrice > 0 and buyoutPrice or nil,
        depositCost = depositCost,
        duration = runTime == 1 and 2 or (runTime == 2 and 8 or 24), -- Convert to hours
        postTime = AuctionTracker:GetTimestamp(),
        texture = texture,
        quality = quality,
        attemptTime = AuctionTracker:GetTimestamp()
    }
    
    lastAuctionAttempt = AuctionTracker:GetTimestamp()
    
    return true
end

-- Calculate estimated deposit cost (1.12 mechanics)
function AuctionHooks:CalculateDepositCost(minBid, buyoutPrice, runTime, count)
    -- In 1.12, deposit is based on vendor price and duration
    -- This is an estimation since we can't get exact vendor price
    local baseDeposit = 0
    
    -- Estimate based on minimum bid (rough approximation)
    -- Actual calculation in 1.12 is more complex
    local estimatedVendorPrice = minBid * 0.1 -- Very rough estimate
    
    -- Duration multiplier
    local durationMultiplier = 1
    if runTime == 1 then -- 2 hours
        durationMultiplier = 1
    elseif runTime == 2 then -- 8 hours
        durationMultiplier = 2
    else -- 24 hours
        durationMultiplier = 4
    end
    
    baseDeposit = math.max(1, math.floor(estimatedVendorPrice * durationMultiplier * count * 0.05))
    
    return baseDeposit
end

-- Process confirmed auction creation
function AuctionHooks:OnAuctionCreated(systemMessage)
    if not pendingAuctionData then
        return
    end
    
    -- Check if this system message is recent enough to match our attempt
    local timeSinceAttempt = AuctionTracker:GetTimestamp() - lastAuctionAttempt
    if timeSinceAttempt > 10 then -- More than 10 seconds old
        return
    end
    
    -- Generate unique auction ID
    local auctionId = self:GenerateAuctionId(pendingAuctionData)
    
    -- Create auction record
    local auction = {
        id = auctionId,
        itemLink = pendingAuctionData.itemLink,
        itemName = pendingAuctionData.itemName,
        itemId = pendingAuctionData.itemId,
        quantity = pendingAuctionData.quantity,
        stackSize = pendingAuctionData.stackSize,
        bidPrice = pendingAuctionData.bidPrice,
        buyoutPrice = pendingAuctionData.buyoutPrice,
        depositCost = pendingAuctionData.depositCost,
        duration = pendingAuctionData.duration,
        postTime = pendingAuctionData.postTime,
        status = "pending",
        soldPrice = nil,
        soldTime = nil,
        buyerName = nil,
        texture = pendingAuctionData.texture,
        quality = pendingAuctionData.quality
    }
    
    -- Store in active auctions
    if AuctionTracker.playerData then
        AuctionTracker.playerData.auctions.active[auctionId] = auction
        
        -- Update statistics
        AuctionTracker.playerData.statistics.totalPosted = AuctionTracker.playerData.statistics.totalPosted + 1
        AuctionTracker.playerData.statistics.totalDeposits = AuctionTracker.playerData.statistics.totalDeposits + auction.depositCost
        AuctionTracker.playerData.statistics.lastUpdated = AuctionTracker:GetTimestamp()
        
        AuctionTracker:Debug("Auction stored: ID %s, %s x%d", auctionId, auction.itemName, auction.quantity)
    end
    
    -- Clear pending data
    pendingAuctionData = nil
end

-- Generate unique auction ID
function AuctionHooks:GenerateAuctionId(auctionData)
    local timestamp = auctionData.postTime or AuctionTracker:GetTimestamp()
    local itemName = auctionData.itemName or "unknown"
    local quantity = auctionData.quantity or 1
    local playerName = AuctionTracker.currentPlayer or "unknown"
    
    -- Create ID using timestamp, item name hash, quantity, and player
    local nameHash = 0
    for i = 1, string.len(itemName) do
        nameHash = nameHash + string.byte(itemName, i)
    end
    
    -- Add some randomness to prevent collisions
    local random = math.random(1000, 9999)
    
    local id = string.format("%d_%d_%d_%s_%d", 
        timestamp, 
        nameHash, 
        quantity, 
        string.sub(playerName, 1, 3), 
        random)
    
    return id
end

-- Clean up expired pending auctions from active list
function AuctionHooks:CleanupExpiredAuctions()
    if not AuctionTracker.playerData or not AuctionTracker.playerData.auctions.active then
        return
    end
    
    local currentTime = AuctionTracker:GetTimestamp()
    local cleaned = 0
    
    for auctionId, auction in pairs(AuctionTracker.playerData.auctions.active) do
        local expirationTime = auction.postTime + (auction.duration * 3600) + 3600 -- Add 1 hour buffer
        
        if currentTime > expirationTime then
            -- Move to history as expired (if not already processed by mail)
            if auction.status == "pending" then
                auction.status = "expired"
                auction.expiredTime = expirationTime - 3600 -- Remove buffer for display
                
                -- Move to history
                AuctionTracker.playerData.auctions.history[auctionId] = auction
                AuctionTracker.playerData.statistics.totalExpired = AuctionTracker.playerData.statistics.totalExpired + 1
            end
            
            -- Remove from active
            AuctionTracker.playerData.auctions.active[auctionId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        AuctionTracker:Debug("Cleaned up %d expired auctions", cleaned)
    end
end

-- Get pending auction data (for system message correlation)
function AuctionHooks:GetPendingAuctionData()
    return pendingAuctionData
end

-- Get time since last auction attempt
function AuctionHooks:GetTimeSinceLastAttempt()
    return AuctionTracker:GetTimestamp() - lastAuctionAttempt
end