-- ============================================================================
-- NO PARTY XP PENALTY
-- ============================================================================
-- Removes the XP reduction when killing mobs in a party.
-- Each player receives XP based on the solo formula with:
--   * 1.05 exponential scaling for mobs above the player's level
--   * Per-kill cap at 1/10 of the XP required for the player's current level
-- ============================================================================

-- ---------------------------------------------------------------------------
-- XP-per-level table (from acore_world.player_xp_for_level)
-- ---------------------------------------------------------------------------

local XP_FOR_LEVEL = {
    [1]=400, [2]=900, [3]=1400, [4]=2100, [5]=2800, [6]=3600, [7]=4500,
    [8]=5400, [9]=6500, [10]=7600, [11]=8800, [12]=10100, [13]=11400,
    [14]=12900, [15]=14400, [16]=16000, [17]=17700, [18]=19400, [19]=21300,
    [20]=23200, [21]=25200, [22]=27300, [23]=29400, [24]=31700, [25]=34000,
    [26]=36400, [27]=38900, [28]=41400, [29]=44300, [30]=47400, [31]=50800,
    [32]=54500, [33]=58600, [34]=62800, [35]=67100, [36]=71600, [37]=76100,
    [38]=80800, [39]=85700, [40]=90700, [41]=95800, [42]=101000, [43]=106300,
    [44]=111800, [45]=117500, [46]=123200, [47]=129100, [48]=135100,
    [49]=141200, [50]=147500, [51]=153900, [52]=160400, [53]=167100,
    [54]=173900, [55]=180800, [56]=187900, [57]=195000, [58]=202300,
    [59]=209800, [60]=494000, [61]=574700, [62]=614400, [63]=650300,
    [64]=682300, [65]=710200, [66]=734100, [67]=753700, [68]=768900,
    [69]=779700, [70]=1523800, [71]=1539600, [72]=1555700, [73]=1571800,
    [74]=1587900, [75]=1604200, [76]=1620700, [77]=1637400, [78]=1653900,
    [79]=1670800,
}

-- ---------------------------------------------------------------------------
-- XP formula helpers (ported from Acore::XP in Formulas.h / Formulas.cpp)
-- ---------------------------------------------------------------------------

local EXP_BASE = 1.05

local function GetGrayLevel(playerLevel)
    if playerLevel <= 5 then
        return 0
    elseif playerLevel <= 39 then
        return playerLevel - 5 - math.floor(playerLevel / 10)
    elseif playerLevel <= 59 then
        return playerLevel - 1 - math.floor(playerLevel / 5)
    else
        return playerLevel - 9
    end
end

local function GetZeroDifference(playerLevel)
    if playerLevel < 8  then return 5
    elseif playerLevel < 10 then return 6
    elseif playerLevel < 12 then return 7
    elseif playerLevel < 16 then return 8
    elseif playerLevel < 20 then return 9
    elseif playerLevel < 30 then return 11
    elseif playerLevel < 40 then return 12
    elseif playerLevel < 45 then return 13
    elseif playerLevel < 50 then return 14
    elseif playerLevel < 55 then return 15
    elseif playerLevel < 60 then return 16
    else return 17
    end
end

-- Determine the nBaseExp constant used in the XP formula.
-- The C++ code uses GetContentLevelsForMapAndZone which looks up the map's
-- expansion via DBC data.  We approximate with map ID + mob level fallback.
--   CONTENT_1_60  -> 45
--   CONTENT_61_70 -> 235
--   CONTENT_71_80 -> 580
local function GetNBaseExp(mapId, mobLevel)
    if mapId == 571 then return 580 end                          -- Northrend
    if mapId == 530 and mobLevel > 60 then return 235 end        -- Outland (TBC mobs)
    if mapId == 0 or mapId == 1 or mapId == 530 then return 45 end -- EK / Kalimdor / BE+Draenei starts
    -- Instances & other maps: guess expansion from mob level
    if mobLevel >= 68 then return 580 end
    if mobLevel >= 58 then return 235 end
    return 45
end

local function BaseGain(playerLevel, mobLevel, mapId)
    local nBaseExp = GetNBaseExp(mapId, mobLevel)

    if mobLevel >= playerLevel then
        local nLevelDiff = mobLevel - playerLevel
        local scale = 20 * (EXP_BASE ^ nLevelDiff)
        return math.floor(((playerLevel * 5 + nBaseExp) * scale / 10 + 1) / 2)
    else
        local grayLevel = GetGrayLevel(playerLevel)
        if mobLevel > grayLevel then
            local ZD = GetZeroDifference(playerLevel)
            return math.floor((playerLevel * 5 + nBaseExp) * (ZD + mobLevel - playerLevel) / ZD)
        end
        return 0
    end
end

-- ---------------------------------------------------------------------------
-- Hook: PLAYER_EVENT_ON_GIVE_XP  (event 12)
-- ---------------------------------------------------------------------------

local function OnGiveXP(event, player, amount, victim)
    if not victim or not player:IsInGroup() then
        return amount
    end

    local playerLevel = player:GetLevel()
    local mobLevel    = victim:GetLevel()
    local mapId       = victim:GetMapId()

    local soloXP = BaseGain(playerLevel, mobLevel, mapId)

    -- Elite mobs give 2x XP (mirrors creature->isElite() check in Gain())
    local ok, rank = pcall(victim.GetRank, victim)
    if ok and rank and (rank == 1 or rank == 2 or rank == 3) then
        soloXP = soloXP * 2
    end

    -- Cap at 1/10 of XP required for this level
    local xpForLevel = XP_FOR_LEVEL[playerLevel]
    if xpForLevel then
        local cap = math.floor(xpForLevel / 10)
        if soloXP > cap then
            soloXP = cap
        end
    end

    -- Never reduce XP below what the group calculation already gave
    return math.max(soloXP, amount)
end

RegisterPlayerEvent(12, OnGiveXP)

print(">> No Party XP Penalty loaded (1.05 exp scaling, 1/10 level cap).")
