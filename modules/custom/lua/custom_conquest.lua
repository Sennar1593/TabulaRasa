-----------------------------------
-- Conquest: OP warps and CP items
-----------------------------------
require("modules/module_utils")
require("scripts/globals/conquest")
require("scripts/globals/teleports")
require("scripts/globals/keyitems")
require("scripts/globals/missions")
require("scripts/globals/npc_util")
require("scripts/globals/settings")
require("scripts/globals/garrison")
require("scripts/globals/status")
require("scripts/globals/zone")
-----------------------------------
local m = Module:new("Custom_Conquest")


-----------------------------------
-- (LOCAL) constants
-----------------------------------

local conquestConstants =
{
    TALLY_START = 0,
    TALLY_END   = 1,
    UPDATE      = 2,
}

-----------------------------------
-- (LOCAL) expeditionary forces
-- TODO: implement this menu
-----------------------------------
--[[
local exForceMenuData =
{
    0x20006, ZULK_EF, 103, 0x000040, 20, xi.ki.ZULKHEIM_EF_INSIGNIA,
    0x20007, NORV_EF, 104, 0x000080, 25, xi.ki.NORVALLEN_EF_INSIGNIA,
    0x20009, DERF_EF, 109, 0x000200, 25, xi.ki.DERFLAND_EF_INSIGNIA,
    0x2000B, KOLS_EF, 118, 0x000800, 20, xi.ki.KOLSHUSHU_EF_INSIGNIA,
    0x2000C, ARAG_EF, 119, 0x001000, 25, xi.ki.ARAGONEU_EF_INSIGNIA,
    0x2000D, FAUR_EF, 111, 0x002000, 35, xi.ki.FAUREGANDI_EF_INSIGNIA,
    0x2000E, VALD_EF, 112, 0x004000, 40, xi.ki.VALDEAUNIA_EF_INSIGNIA,
    0x2000F, QUFI_EF, 126, 0x008000, 25, xi.ki.QUFIM_EF_INSIGNIA,
    0x20010, LITE_EF, 121, 0x010000, 35, xi.ki.LITELOR_EF_INSIGNIA,
    0x20011, KUZO_EF, 114, 0x020000, 40, xi.ki.KUZOTZ_EF_INSIGNIA,
    0x20012, VOLL_EF, 113, 0x040000, 65, xi.ki.VOLLBOW_EF_INSIGNIA,
    0x20013, ELLO_EF, 123, 0x080000, 35, xi.ki.ELSHIMO_LOWLANDS_EF_INSIGNIA,
    0x20014, ELUP_EF, 124, 0x100000, 45, xi.ki.ELSHIMO_UPLANDS_EF_INSIGNIA
}
]]--
local function getExForceAvailable(player, guardNation)
    return 0
end

local function getExForceReward(player, guardNation)
    return 0
end

-----------------------------------
-- (LOCAL) outposts
-----------------------------------

local outposts =
{
    [xi.region.RONFAURE]        = {zone = 100, ki = xi.ki.RONFAURE_SUPPLIES,              cp = 10, lvl = 10, fee = 100},
    [xi.region.ZULKHEIM]        = {zone = 103, ki = xi.ki.ZULKHEIM_SUPPLIES,              cp = 30, lvl = 10, fee = 100},
    [xi.region.NORVALLEN]       = {zone = 104, ki = xi.ki.NORVALLEN_SUPPLIES,             cp = 40, lvl = 15, fee = 150},
    [xi.region.GUSTABERG]       = {zone = 106, ki = xi.ki.GUSTABERG_SUPPLIES,             cp = 10, lvl = 10, fee = 100},
    [xi.region.DERFLAND]        = {zone = 109, ki = xi.ki.DERFLAND_SUPPLIES,              cp = 40, lvl = 15, fee = 150},
    [xi.region.SARUTABARUTA]    = {zone = 115, ki = xi.ki.SARUTABARUTA_SUPPLIES,          cp = 10, lvl = 10, fee = 100},
    [xi.region.KOLSHUSHU]       = {zone = 118, ki = xi.ki.KOLSHUSHU_SUPPLIES,             cp = 40, lvl = 10, fee = 100},
    [xi.region.ARAGONEU]        = {zone = 119, ki = xi.ki.ARAGONEU_SUPPLIES,              cp = 40, lvl = 15, fee = 150},
    [xi.region.FAUREGANDI]      = {zone = 111, ki = xi.ki.FAUREGANDI_SUPPLIES,            cp = 70, lvl = 35, fee = 350},
    [xi.region.VALDEAUNIA]      = {zone = 112, ki = xi.ki.VALDEAUNIA_SUPPLIES,            cp = 50, lvl = 40, fee = 400},
    [xi.region.QUFIMISLAND]     = {zone = 126, ki = xi.ki.QUFIM_SUPPLIES,                 cp = 60, lvl = 15, fee = 150},
    [xi.region.LITELOR]         = {zone = 121, ki = xi.ki.LITELOR_SUPPLIES,               cp = 40, lvl = 25, fee = 250},
    [xi.region.KUZOTZ]          = {zone = 114, ki = xi.ki.KUZOTZ_SUPPLIES,                cp = 70, lvl = 30, fee = 300},
    [xi.region.VOLLBOW]         = {zone = 113, ki = xi.ki.VOLLBOW_SUPPLIES,               cp = 70, lvl = 50, fee = 500},
    [xi.region.ELSHIMOLOWLANDS] = {zone = 123, ki = xi.ki.ELSHIMO_LOWLANDS_SUPPLIES,      cp = 70, lvl = 25, fee = 250},
    [xi.region.ELSHIMOUPLANDS]  = {zone = 124, ki = xi.ki.ELSHIMO_UPLANDS_SUPPLIES,       cp = 70, lvl = 35, fee = 350},
    [xi.region.TULIA]           = {zone = 130,                                             cp = 0,  lvl = 70, fee = 500},
    [xi.region.MOVALPOLOS]      = {zone =  11,                                             cp = 40, lvl = 25, fee = 250},
    [xi.region.TAVNAZIANARCH]   = {zone =  24, ki = xi.ki.TAVNAZIAN_ARCHIPELAGO_SUPPLIES, cp = 70, lvl = 30, fee = 300},
}

local function hasOutpost(player, region)
    local hasOP = player:hasTeleport(player:getNation(), region + 5)
    if not hasOP then
        if xi.settings.UNLOCK_OUTPOST_WARPS == 2 then
            hasOP = true
        elseif xi.settings.UNLOCK_OUTPOST_WARPS == 1 then
            hasOP = region <= xi.region.ELSHIMOUPLANDS
        end
    end
    return hasOP
end

local function setHomepointFee(player, guardNation)
    local pNation = player:getNation()
    local fee = 0

    if pNation ~= guardNation and not xi.conquest.areAllies(pNation, guardNation) then
        local rank = player:getRank(player:getNation())
        if rank <= 5 then
            fee = 100 * math.pow(2, rank - 1)
        else
            fee = (800 * rank) - 2400
        end
    end

    return fee
end

local function getRegionsMask(nation)
    local mask = 0
    for region = xi.region.RONFAURE, xi.region.TAVNAZIANARCH do
        if GetRegionOwner(region) == nation then
            mask = bit.bor(mask, bit.lshift(1, region + 5)) -- Region bits start at 5th bit
        end
    end

    return mask
end

local function getAllowedTeleports(player, nation)
    local allowedTeleports = 0x3F40001F -- All outposts set (0 indicates allowed)

    if xi.settings.UNLOCK_OUTPOST_WARPS == 2 then
        return allowedTeleports -- Allow all outposts
    elseif xi.settings.UNLOCK_OUTPOST_WARPS == 1 then
        return 0x3FE0001F -- Allow all outposts except for Tulia and Tavnazia
    end
    for region = xi.region.RONFAURE, xi.region.TAVNAZIANARCH do
        if not xi.conquest.canTeleportToOutpost(player, region) then
            allowedTeleports = bit.bor(allowedTeleports, bit.lshift(1, region + 5)) -- Region bits start at 5th bit
        end
    end

    return allowedTeleports
end

-----------------------------------
-- (LOCAL) supply runs
-----------------------------------

-- produce supply quest mask for the nation based on current conquest standings
local function suppliesAvailableBitmask(player, nation)
    local mask = 2130706463

    if player:getCharVar("supplyQuest_started") == vanaDay() then
        mask = 4294967295 -- Need to wait 1 vanadiel day
    end

    for k, v in pairs(outposts) do
        if v.ki and player:hasKeyItem(v.ki) then
            mask = -1
            break
        end
    end

    if mask ~= -1 and mask ~= 4294967295 then
        for i = 0, 18 do
--            if GetRegionOwner(i) ~= nation or i == 16 or i == 17 or (i == 18 and not player:hasCompletedMission(xi.mission.log_id.COP, xi.mission.id.cop.DARKNESS_NAMED)) then
                mask = mask + 2^(i + 5)
--            end
        end
    end

    return mask
end

local function areSuppliesRotten(player, npc, guardType)
    local fresh   = player:getCharVar("supplyQuest_fresh")
    local region  = player:getCharVar("supplyQuest_region")
    local rotten  = false
    local text    = zones[player:getZoneID()].text

    if region > 0 and fresh <= os.time() then
        rotten = true
    end

    if rotten then
        if guardType <= xi.conquest.guard.FOREIGN then
            player:showText(npc, text.CONQUEST + 40) -- "We will dispose of those unusable supplies."
        else
            player:showText(npc, text.CONQUEST - 1) -- "Hmm... These supplies you have brought us are too old to be of any use."
        end
        local ki = outposts[region].ki

        player:delKeyItem(ki)
        player:messageSpecial(text.KEYITEM_LOST, ki)
        player:setCharVar("supplyQuest_started", 0)
        player:setCharVar("supplyQuest_region", 0)
        player:setCharVar("supplyQuest_fresh", 0)
    end

    return rotten
end

local function canDeliverSupplies(player, guardNation, guardEvent, guardRegion)
    local delivered = false

    local region = player:getCharVar("supplyQuest_region")
    if region == guardRegion and player:hasKeyItem(outposts[region].ki) then
        delivered = true
        player:startEvent(guardEvent, 16, 0, 0, 0, 1, 0, 0, 255) -- "you have brought us supplies!"
    end

    return delivered
end

-----------------------------------
-- (LOCAL) overseers
-----------------------------------

local overseerOffsets =
{
    [xi.region.RONFAURE] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Doladepaiton, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Ballie, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- Flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- Flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Yoshihiro, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Molting Moth, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- Flag
        {offset = 12, nation = xi.nation.BASTOK},   -- Flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Kyanta-Pakyanta, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Tottoto, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- Flag
        {offset = 13, nation = xi.nation.WINDURST}, -- Flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- Flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- Flag
        {offset = 10, nation = xi.nation.OTHER},    -- Harvetour
    },
    [xi.region.ZULKHEIM] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Quanteilleron, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Prunilla, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Tsunashige, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Fighting Ant, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 13, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Nyata-Mobuta, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Tebubu, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 14, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 15, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Medicine Axe
    },
    [xi.region.NORVALLEN] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Chaplion, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Taumiale, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Takamoto, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Pure Heart, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Bubchu-Bibinchu, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Geruru, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Mionie
    },
    [xi.region.GUSTABERG] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Ennigreaud, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Quellebie, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Shigezane, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Heavy Fog, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Kuuwari-Aori, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Butsutsu, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Kuleo
    },
    [xi.region.DERFLAND] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Mesachedeau, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Ioupie, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Souun, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Sharp Tooth, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Mokto-Lankto, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Shikoko, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Tahmasp
    },
    [xi.region.SARUTABARUTA] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Naguipeillont, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Banege, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Ryokei, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Slow Axe, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Roshina-Kuleshuna, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Darumomo, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Mahien-Uhien
    },
    [xi.region.KOLSHUSHU] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Bonbavour, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Craigine, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Ishin, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Wise Turtle, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Ganemu-Punnemu, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Mashasha, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Lobho Ukipturi
    },
    [xi.region.ARAGONEU] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Chegourt, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Buliame, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Akane, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Three Steps, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Donmo-Boronmo, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Daruru, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Mushosho
    },
    [xi.region.FAUREGANDI] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Parledaire, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Leaufetie, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Akane, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Rattling Rain, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Ryunchi-Pauchi, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Chopapa, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Gueriette
    },
    [xi.region.VALDEAUNIA] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Jeantelas, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Pilcha, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Kaya, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Heavy Bear, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Magumo-Yagimo, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Tememe, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Pelogrant
    },
    [xi.region.QUFIMISLAND] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Pitoire, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Matica, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Sasa, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Singing Blade, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Tsonga-Hoponga, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Numumu, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Jiwon
    },
    [xi.region.LITELOR] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Credaurion, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Limion, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Calliope, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Dedden, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Ajimo-Majimo, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Ochocho, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Kasim
    },
    [xi.region.KUZOTZ] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Eaulevisat, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Laimeve, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Lindgard, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Daborn, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Variko-Njariko, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Sahgygy, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Sowande
    },
    [xi.region.VOLLBOW] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Salimardi, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Paise, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Sarmistha, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Dultwa, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Voranbo-Natanbo, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Orukeke, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Bright Moon
    },
    [xi.region.ELSHIMOLOWLANDS] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Zorchorevi, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Mupia, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Mahol, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Bammiro, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Uphra-Kophra, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Richacha, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Robino-Mobino
    },
    [xi.region.ELSHIMOUPLANDS] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Ilieumort, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Emila, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Mintoo, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Guddal, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Etaj-Pohtaj, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Ghantata, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Mugha Dovajaiho
    },
    [xi.region.TULIA] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- flag
        {offset =  3, nation = xi.nation.BEASTMEN}, -- flag
    },
    [xi.region.MOVALPOLOS] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- flag
        {offset =  3, nation = xi.nation.BEASTMEN}, -- flag
    },
    [xi.region.TAVNAZIANARCH] =
    {
        {offset =  0, nation = xi.nation.SANDORIA}, -- Jemmoquel, R.K.
        {offset =  7, nation = xi.nation.SANDORIA}, -- Chilaumme, R.K.
        {offset =  3, nation = xi.nation.SANDORIA}, -- flag
        {offset = 11, nation = xi.nation.SANDORIA}, -- flag
        {offset =  1, nation = xi.nation.BASTOK},   -- Yoram, I.M.
        {offset =  8, nation = xi.nation.BASTOK},   -- Ghost Talker, I.M.
        {offset =  4, nation = xi.nation.BASTOK},   -- flag
        {offset = 12, nation = xi.nation.BASTOK},   -- flag
        {offset =  2, nation = xi.nation.WINDURST}, -- Teldo-Moroldo, W.W.
        {offset =  9, nation = xi.nation.WINDURST}, -- Cotete, W.W.
        {offset =  5, nation = xi.nation.WINDURST}, -- flag
        {offset = 13, nation = xi.nation.WINDURST}, -- flag
        {offset =  6, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 14, nation = xi.nation.BEASTMEN}, -- flag
        {offset = 10, nation = xi.nation.OTHER},    -- Jersey
    },
}

local crystals =
{
    [4096] = 12,
    [4097] = 12,
    [4098] = 12,
    [4099] = 12,
    [4100] = 12,
    [4101] = 12,
    [4102] = 16,
    [4103] = 16,
    [4238] = 12,
    [4239] = 12,
    [4240] = 12,
    [4241] = 12,
    [4242] = 12,
    [4243] = 12,
    [4244] = 16,
    [4245] = 16,
}

local expRings =
{
    [15761] = {cp=350, charges=7},
    [15762] = {cp=700, charges=7},
    [15763] = {cp=600, charges=3},
}

local function conquestRanking()
    -- computes part of argument 3 for gate guard events. represents the conquest standing of the 3 nations. Verified.
    return 1 + 4 * 1 + 16 * 1
end

xi.conquest.toggleRegionalNPCs = function(zone)
    -- Show/Hide regional NPCs
    -- If there is a draw or a 1st place Alliance, those NPCs won't be available.
    local id = zone:getID()
    if
        id == xi.zone.PORT_BASTOK or
        id == xi.zone.SOUTHERN_SAN_DORIA or
        id == xi.zone.WINDURST_WOODS
    then
        local regionalNPCNames =
        {
            "Nokkhi_Jinjahl",
            "Ominous_Cloud",
            "Valeriano",
            "Mokop-Sankop",
            "Cheh_Raihah",
            "Nalta",
            "Dahjal"
        }

        -- TODO: Do we need to worry about beastmen's rank?
        local rankings =
        {
            { GetNationRank(xi.nation.SANDORIA), xi.zone.SOUTHERN_SAN_DORIA },
            { GetNationRank(xi.nation.BASTOK), xi.zone.PORT_BASTOK },
            { GetNationRank(xi.nation.WINDURST), xi.zone.WINDURST_WOODS },
        }

        table.sort(rankings, function (a, b) return a[1] > b[1] end)

        local firstPlaceZone = rankings[1][2]

        if firstPlaceZone == zone:getID() then
            print("Making regional conquest NPCs available in: " .. zone:getName())
        end

        for _, name in pairs(regionalNPCNames) do
            local results = zone:queryEntitiesByName(name)
            for _, entity in pairs(results) do
                -- Will be the real entity if it has an X position
                if math.abs(entity:getXPos()) > 0 then
                    -- Hide all of these NPCs by default
                    entity:setStatus(xi.status.DISAPPEAR)

                    -- If there is a clear winner, and not a tie,
                    -- show the NPCs
                    if id == firstPlaceZone and not IsConquestAlliance() then
                        entity:setStatus(xi.status.NORMAL)
                    end
                end
            end
        end
    end
end

local function getArg1(player, guardNation, guardType)
    local pNation = player:getNation()
    local output = 0
    local signet = 0

    if guardNation == xi.nation.WINDURST then
        output = 33
    elseif guardNation == xi.nation.SANDORIA then
        output = 1
    elseif guardNation == xi.nation.BASTOK then
        output = 17
    end

    if guardNation == pNation then
        signet = 0
    else
        signet = 7
        if xi.conquest.areAllies(pNation, guardNation) then
            signet = 2^(2 - pNation)
        end
    end

    if guardNation == xi.nation.OTHER then
        output = (pNation * 16) + (3 * 256) + 65537
    else
        output = output + 256 * signet
    end

    if guardType >= xi.conquest.guard.OUTPOST then
        output = output - 1
    end

    if output >= 1792 and guardType >= xi.conquest.guard.OUTPOST then
        output = 1808
    end

    return output
end

-- arg6 encodes a player's rank and nationality:
-- bits 1-4 encode the rank of the player (verified that bit 4 is part of the rank number so ranks could have gone up to 31.)
-- bits 5-6 seem to encode the citizenship as below. This part needs more testing and verification.

local function getArg6(player)
    return player:getRank(player:getNation()) + (player:getNation() * 32)
end

-----------------------------------
-- (LOCAL) overseer stock
-----------------------------------

local overseerInvCommon =
{
    [32928] = {cp =     7, lvl =  1, item =  4182},             -- scroll_of_instant_reraise
    [32929] = {cp =    10, lvl =  1, item =  4181},             -- scroll_of_instant_warp
    [32930] = {cp =  2500, lvl =  1, item = 15542},             -- return_ring
    [32931] = {cp =  9000, lvl =  1, item = 15541},             -- homing_ring
    [32933] = {cp =   500, lvl =  1, item = 15761},             -- chariot_band
    [32934] = {cp =  1000, lvl =  1, item = 15762},             -- empress_band
    [32935] = {cp =  2000, lvl =  1, item = 15763},             -- emperor_band
    [32936] = {cp =  5000, lvl =  1, item = 28540},             -- warp_ring
    [32941] = {cp = 20000, lvl =  1, item =  6380, rank = 10},  -- refined_chair_set
}

local overseerInvNation =
{
    [0] = -- San d'Oria
    {
        [32768] = {rank =  1, cp =  1000, lvl = 10, item = 17167},                -- royal_archers_longbow
        [32769] = {rank =  1, cp =  1000, lvl = 10, item = 16544},                -- royal_archers_sword
        [32770] = {rank =  1, cp =  1000, lvl = 10, item = 12510},                -- royal_footmans_bandana
        [32771] = {rank =  1, cp =  1000, lvl = 10, item = 12753},                -- royal_footmans_gloves
        [32772] = {rank =  1, cp =  1000, lvl = 10, item = 13004},                -- royal_footmans_boots
        [32773] = {rank =  1, cp =  1000, lvl = 10, item = 16691},                -- royal_archers_cesti
        [32774] = {rank =  1, cp =  1000, lvl = 10, item = 13718},                -- royal_footmans_tunic
        [32784] = {rank =  2, cp =  2000, lvl = 18, item = 16852},                -- royal_spearmans_spear
        [32785] = {rank =  2, cp =  2000, lvl = 10, item = 12630},                -- royal_footmans_vest
        [32786] = {rank =  2, cp =  2000, lvl = 20, item = 12882},                -- royal_footmans_trousers
        [32787] = {rank =  2, cp =  2000, lvl = 20, item = 17367},                -- royal_spearmans_horn
        [32788] = {rank =  2, cp =  2000, lvl = 20, item = 13045},                -- royal_footmans_clogs
        [32800] = {rank =  3, cp =  4000, lvl = 30, item = 16844},                -- royal_squires_halberd
        [32801] = {rank =  3, cp =  4000, lvl = 30, item = 13104},                -- royal_squires_collar
        [32802] = {rank =  3, cp =  4000, lvl = 30, item = 12431},                -- royal_squires_helm
        [32803] = {rank =  3, cp =  4000, lvl = 30, item = 12687},                -- royal_squires_mufflers
        [32804] = {rank =  3, cp =  4000, lvl = 30, item = 12943},                -- royal_squires_sollerets
        [32805] = {rank =  3, cp =  4000, lvl = 30, item = 16744},                -- royal_squires_dagger
        [32806] = {rank =  3, cp =  4000, lvl = 30, item = 17150},                -- royal_squires_mace
        [32807] = {rank =  3, cp =  4000, lvl =  1, item = 13495},                -- san_dorian_ring
        [32816] = {rank =  4, cp =  8000, lvl = 40, item = 16601},                -- royal_swordsmans_blade
        [32817] = {rank =  4, cp =  8000, lvl = 40, item = 12559},                -- royal_squires_chainmail
        [32818] = {rank =  4, cp =  8000, lvl = 40, item = 12815},                -- royal_squires_breeches
        [32819] = {rank =  4, cp =  8000, lvl = 40, item = 13719},                -- royal_squires_robe
        [32820] = {rank =  4, cp =  8000, lvl = 40, item = 12336},                -- royal_squires_shield
        [32832] = {rank =  5, cp = 16000, lvl = 50, item = 16851},                -- royal_knight_army_lance
        [32833] = {rank =  5, cp = 16000, lvl = 50, item = 16571},                -- temple_knight_army_sword
        [32834] = {rank =  5, cp = 16000, lvl = 50, item = 12312},                -- royal_knight_army_shield
        [32835] = {rank =  5, cp = 16000, lvl = 50, item = 12313},                -- temple_knight_army_shield
        [32836] = {rank =  5, cp = 16000, lvl = 50, item = 13107},                -- royal_knight_army_collar
        [32837] = {rank =  5, cp = 16000, lvl = 50, item = 13105},                -- temple_knight_army_collar
        [32838] = {rank =  5, cp = 16000, lvl = 50, item = 12686},                -- royal_knights_mufflers
        [32839] = {rank =  5, cp = 16000, lvl = 50, item = 12942},                -- royal_knights_sollerets
        [32840] = {rank =  5, cp = 16000, lvl = 50, item = 13220},                -- royal_knights_belt
        [32841] = {rank =  5, cp = 16000, lvl = 50, item = 13720},                -- royal_knights_cloak
        [32848] = {rank =  6, cp = 24000, lvl = 55, item = 13580},                -- royal_army_mantle
        [32849] = {rank =  6, cp = 24000, lvl = 55, item = 13106},                -- royal_guards_collar
        [32850] = {rank =  6, cp = 24000, lvl = 55, item = 12430},                -- royal_knights_bascinet
        [32851] = {rank =  6, cp = 24000, lvl = 55, item = 13722},                -- royal_knights_aketon
        [32852] = {rank =  6, cp = 24000, lvl = 55, item = 12558},                -- royal_knights_chainmail
        [32853] = {rank =  6, cp = 24000, lvl = 55, item = 12814},                -- royal_knights_breeches
        [32854] = {rank =  6, cp = 24000, lvl = 55, item = 12321},                -- royal_guards_shield
        [32855] = {rank =  6, cp = 24000, lvl = 55, item = 17067},                -- royal_guards_rod
        [32856] = {rank =  6, cp = 24000, lvl = 55, item = 16599},                -- royal_guards_sword
        [32857] = {rank =  6, cp = 24000, lvl = 55, item = 16805},                -- royal_guards_fleuret
        [32864] = {rank =  7, cp = 32000, lvl = 60, item = 15956},                -- temple_knights_quiver
        [32865] = {rank =  7, cp = 32000, lvl = 60, item = 16886},                -- grand_knights_lance
        [32866] = {rank =  7, cp = 32000, lvl = 60, item = 13557},                -- grand_knights_ring
        [32880] = {rank =  8, cp = 40000, lvl = 65, item = 14013},                -- grand_temple_knights_gauntlets
        [32881] = {rank =  8, cp = 40000, lvl = 65, item = 14014},                -- grand_temple_knights_bangles
        [32882] = {rank =  8, cp = 40000, lvl = 65, item = 13140},                -- grand_temple_knights_collar
        [32896] = {rank =  9, cp = 48000, lvl = 71, item = 16953},                -- reserve_captains_greatsword
        [32897] = {rank =  9, cp = 48000, lvl = 71, item = 17934},                -- reserve_captains_pick
        [32898] = {rank =  9, cp = 48000, lvl = 71, item = 17458},                -- reserve_captains_mace
        [32899] = {rank =  9, cp = 48000, lvl = 71, item = 16893},                -- reserve_captains_lance
        [32912] = {rank = 10, cp = 56000, lvl =  1, item = 14428},                -- kingdom_aketon
        [32932] = {           cp =  5000, lvl =  1, item = 17583},                -- kingdom_signet_staff
        [32940] = {rank = 10, cp = 10000, lvl =  1, item =  6377},                -- imperial_chair_set
    },
    [1] = -- Bastok
    {
        [32768] = {rank =  1, cp =  1000, lvl = 10, item = 16433},                -- legionnaires_knuckles
        [32769] = {rank =  1, cp =  1000, lvl = 10, item = 17223},                -- legionnaires_crossbow
        [32770] = {rank =  1, cp =  1000, lvl = 10, item = 16648},                -- legionnaires_axe
        [32771] = {rank =  1, cp =  1000, lvl = 10, item = 12509},                -- legionnaires_cap
        [32772] = {rank =  1, cp =  1000, lvl = 10, item = 12752},                -- legionnaires_mittens
        [32773] = {rank =  1, cp =  1000, lvl = 10, item = 13003},                -- legionnaires_leggings
        [32774] = {rank =  1, cp =  1000, lvl = 10, item = 17128},                -- legionnaires_staff
        [32775] = {rank =  1, cp =  1000, lvl = 10, item = 16780},                -- legionnaires_scythe
        [32784] = {rank =  2, cp =  2000, lvl = 18, item = 17048},                -- decurions_hammer
        [32785] = {rank =  2, cp =  2000, lvl = 10, item = 12629},                -- legionnaires_harness
        [32786] = {rank =  2, cp =  2000, lvl = 20, item = 12881},                -- legionnaires_subligar
        [32787] = {rank =  2, cp =  2000, lvl = 20, item = 16745},                -- decurions_dagger
        [32788] = {rank =  2, cp =  2000, lvl = 20, item = 12337},                -- decurions_shield
        [32800] = {rank =  3, cp =  4000, lvl = 30, item = 16712},                -- centurions_axe
        [32801] = {rank =  3, cp =  4000, lvl = 10, item = 13098},                -- republican_bronze_medal
        [32802] = {rank =  3, cp =  4000, lvl = 30, item = 12438},                -- centurions_visor
        [32803] = {rank =  3, cp =  4000, lvl = 30, item = 12566},                -- centurions_scale_mail
        [32804] = {rank =  3, cp =  4000, lvl = 30, item = 12694},                -- centurions_finger_gauntlets
        [32805] = {rank =  3, cp =  4000, lvl = 30, item = 12822},                -- centurions_cuisses
        [32806] = {rank =  3, cp =  4000, lvl = 30, item = 12950},                -- centurions_greaves
        [32807] = {rank =  3, cp =  4000, lvl = 30, item = 16806},                -- centurions_sword
        [32808] = {rank =  3, cp =  4000, lvl = 30, item = 13830},                -- legionnaires_circlet
        [32809] = {rank =  3, cp =  4000, lvl =  1, item = 13497},                -- bastokan_ring
        [32816] = {rank =  4, cp =  8000, lvl = 40, item = 16516},                -- junior_musketeers_tuck
        [32817] = {rank =  4, cp =  8000, lvl = 40, item = 12422},                -- iron_musketeers_armet
        [32818] = {rank =  4, cp =  8000, lvl = 40, item = 12678},                -- iron_musketeers_gauntlets
        [32819] = {rank =  4, cp =  8000, lvl = 40, item = 12934},                -- iron_musketeers_sabatons
        [32820] = {rank =  4, cp =  8000, lvl = 40, item = 13721},                -- iron_musketeers_gambison
        [32821] = {rank =  4, cp =  8000, lvl = 40, item = 17283},                -- junior_musketeers_chakram
        [32832] = {rank =  5, cp = 16000, lvl = 50, item = 16529},                -- musketeers_sword
        [32833] = {rank =  5, cp = 16000, lvl = 30, item = 13099},                -- republican_iron_medal
        [32834] = {rank =  5, cp = 16000, lvl = 50, item = 12550},                -- iron_musketeers_cuirass
        [32835] = {rank =  5, cp = 16000, lvl = 50, item = 12806},                -- iron_musketeers_cuisses
        [32836] = {rank =  5, cp = 16000, lvl = 50, item = 17129},                -- musketeers_pole
        [32837] = {rank =  5, cp = 16000, lvl = 50, item = 17253},                -- musketeer_gun
        [32848] = {rank =  6, cp = 24000, lvl = 55, item = 13100},                -- republican_mythril_medal
        [32849] = {rank =  6, cp = 24000, lvl = 55, item = 13582},                -- republican_army_mantle
        [32850] = {rank =  6, cp = 24000, lvl = 55, item = 16557},                -- musketeer_commanders_falchion
        [32851] = {rank =  6, cp = 24000, lvl = 55, item = 12304},                -- musketeer_commanders_shield
        [32852] = {rank =  6, cp = 24000, lvl = 55, item = 17151},                -- musketeer_commanders_rod
        [32853] = {rank =  6, cp = 24000, lvl = 55, item = 13064},                -- iron_musketeers_gorget
        [32864] = {rank =  7, cp = 32000, lvl = 60, item = 15957},                -- iron_musketeers_quiver
        [32865] = {rank =  7, cp = 32000, lvl = 60, item = 17807},                -- gold_musketeers_uchigatana
        [32866] = {rank =  7, cp = 32000, lvl = 60, item = 13558},                -- gold_musketeers_ring
        [32880] = {rank =  8, cp = 40000, lvl = 65, item = 14015},                -- praefectuss_gloves
        [32881] = {rank =  8, cp = 40000, lvl = 65, item = 13880},                -- presidential_hairpin
        [32882] = {rank =  8, cp = 40000, lvl = 65, item = 13141},                -- republican_gold_medal
        [32896] = {rank =  9, cp = 48000, lvl = 71, item = 16799},                -- senior_gold_musketeers_scythe
        [32897] = {rank =  9, cp = 48000, lvl = 71, item = 17457},                -- senior_gold_musketeers_rod
        [32898] = {rank =  9, cp = 48000, lvl = 71, item = 18196},                -- senior_gold_musketeers_axe
        [32899] = {rank =  9, cp = 48000, lvl = 71, item = 17655},                -- senior_gold_musketeers_scimitar
        [32912] = {rank = 10, cp = 56000, lvl =  1, item = 14429},                -- republic_aketon
        [32932] = {           cp =  5000, lvl =  1, item = 17584},                -- republic_signet_staff
        [32940] = {rank = 10, cp = 10000, lvl =  1, item =  6378},                -- decorative_chair_set
    },
    [2] = -- Windurst
    {
        [32768] = {rank =  1, cp =  1000, lvl = 10, item = 17159},                -- freeswords_bow
        [32769] = {rank =  1, cp =  1000, lvl = 10, item = 17028},                -- freeswords_club
        [32770] = {rank =  1, cp =  1000, lvl = 10, item = 16442},                -- freeswords_baghnakhs
        [32771] = {rank =  1, cp =  1000, lvl = 10, item = 12915},                -- freeswords_slops
        [32772] = {rank =  1, cp =  1000, lvl = 10, item = 17130},                -- freeswords_staff
        [32784] = {rank =  2, cp =  2000, lvl = 18, item = 17103},                -- mercenarys_pole
        [32785] = {rank =  2, cp =  2000, lvl = 20, item = 12484},                -- mercenarys_hachimaki
        [32786] = {rank =  2, cp =  2000, lvl = 20, item = 12653},                -- mercenarys_gi
        [32787] = {rank =  2, cp =  2000, lvl = 20, item = 12719},                -- mercenarys_tekko
        [32788] = {rank =  2, cp =  2000, lvl = 20, item = 12855},                -- mercenarys_sitabaki
        [32789] = {rank =  2, cp =  2000, lvl = 20, item = 12975},                -- mercenarys_kyahan
        [32790] = {rank =  2, cp =  2000, lvl = 20, item = 16746},                -- mercenarys_knife
        [32791] = {rank =  2, cp =  2000, lvl = 20, item = 16930},                -- mercenarys_greatsword
        [32800] = {rank =  3, cp =  4000, lvl = 30, item = 16776},                -- mercenary_captains_scythe
        [32801] = {rank =  3, cp =  4000, lvl = 30, item = 12470},                -- mercenary_captains_headgear
        [32802] = {rank =  3, cp =  4000, lvl = 30, item = 12598},                -- mercenary_captains_doublet
        [32803] = {rank =  3, cp =  4000, lvl = 30, item = 12726},                -- mercenary_captains_gloves
        [32804] = {rank =  3, cp =  4000, lvl = 30, item = 12854},                -- mercenary_captains_hose
        [32805] = {rank =  3, cp =  4000, lvl = 30, item = 12982},                -- mercenary_captains_gaiters
        [32806] = {rank =  3, cp =  4000, lvl = 30, item = 16747},                -- mercenary_captains_kukri
        [32807] = {rank =  3, cp =  4000, lvl = 30, item = 13221},                -- mercenary_captains_belt
        [32808] = {rank =  3, cp =  4000, lvl =  1, item = 13496},                -- windurstian_ring
        [32816] = {rank =  4, cp =  8000, lvl = 40, item = 16463},                -- combat_casters_dagger
        [32817] = {rank =  4, cp =  8000, lvl = 40, item = 17282},                -- combat_casters_boomerang
        [32818] = {rank =  4, cp =  8000, lvl = 10, item = 13101},                -- green_scarf
        [32819] = {rank =  4, cp =  8000, lvl = 40, item = 12614},                -- combat_casters_cloak
        [32820] = {rank =  4, cp =  8000, lvl = 40, item = 12743},                -- combat_casters_mitts
        [32821] = {rank =  4, cp =  8000, lvl = 40, item = 12870},                -- combat_casters_slacks
        [32822] = {rank =  4, cp =  8000, lvl = 40, item = 12998},                -- combat_casters_shoes
        [32823] = {rank =  4, cp =  8000, lvl = 40, item = 16807},                -- combat_casters_scimitar
        [32824] = {rank =  4, cp =  8000, lvl = 40, item = 16669},                -- combat_casters_axe
        [32832] = {rank =  5, cp = 16000, lvl = 50, item = 17082},                -- tactician_magicians_wand
        [32833] = {rank =  5, cp = 16000, lvl = 30, item = 13102},                -- paisley_scarf
        [32834] = {rank =  5, cp = 16000, lvl = 50, item = 12478},                -- tactician_magicians_hat
        [32835] = {rank =  5, cp = 16000, lvl = 50, item = 12606},                -- tactician_magicians_coat
        [32836] = {rank =  5, cp = 16000, lvl = 50, item = 12734},                -- tactician_magicians_cuffs
        [32837] = {rank =  5, cp = 16000, lvl = 50, item = 12862},                -- tactician_magicians_slops
        [32838] = {rank =  5, cp = 16000, lvl = 50, item = 12990},                -- tactician_magicians_pigaches
        [32839] = {rank =  5, cp = 16000, lvl = 50, item = 16810},                -- tactician_magicians_espadon
        [32840] = {rank =  5, cp = 16000, lvl = 50, item = 16694},                -- tactician_magicians_hooks
        [32848] = {rank =  6, cp = 24000, lvl = 55, item = 13103},                -- checkered_scarf
        [32849] = {rank =  6, cp = 24000, lvl = 55, item = 13581},                -- federal_army_mantle
        [32850] = {rank =  6, cp = 24000, lvl = 55, item = 17094},                -- wise_wizards_staff
        [32851] = {rank =  6, cp = 24000, lvl = 55, item = 16808},                -- wise_wizards_bilbo
        [32852] = {rank =  6, cp = 24000, lvl = 55, item = 16809},                -- wise_wizards_anelace
        [32864] = {rank =  7, cp = 32000, lvl = 60, item = 15958},                -- combat_casters_quiver
        [32865] = {rank =  7, cp = 32000, lvl = 60, item = 12363},                -- patriarch_protectors_shield
        [32866] = {rank =  7, cp = 32000, lvl = 60, item = 13559},                -- patriarch_protectors_ring
        [32880] = {rank =  8, cp = 40000, lvl = 65, item = 14016},                -- master_casters_mitts
        [32881] = {rank =  8, cp = 40000, lvl = 65, item = 14017},                -- master_casters_bracelets
        [32882] = {rank =  8, cp = 40000, lvl = 65, item = 13142},                -- windurstian_scarf
        [32896] = {rank =  9, cp = 48000, lvl = 71, item = 18145},                -- master_casters_bow
        [32897] = {rank =  9, cp = 48000, lvl = 71, item = 17530},                -- master_casters_pole
        [32898] = {rank =  9, cp = 48000, lvl = 71, item = 17508},                -- master_casters_baghnakhs
        [32899] = {rank =  9, cp = 48000, lvl = 71, item = 17617},                -- master_casters_knife
        [32912] = {rank = 10, cp = 56000, lvl =  1, item = 14430},                -- federation_aketon
        [32932] = {           cp =  5000, lvl =  1, item = 17585},                -- federation_signet_staff
        [32940] = {rank = 10, cp = 10000, lvl =  1, item =  6379},                -- ornate_stool_set
    },
}

local function getStock(player, guardNation, option)
    local r = overseerInvCommon[option]
    if r == nil then
        if guardNation == xi.nation.OTHER then
            r = overseerInvNation[player:getNation()][option]
        else
            r = overseerInvNation[guardNation][option]
        end
    end
    return r
end

local function canBuyExpRing(player, item)
    local text = zones[player:getZoneID()].text

    -- check exp ring count
    if xi.settings.ALLOW_MULTIPLE_EXP_RINGS ~= 1 then
        for i = 15761, 15763 do
            if player:hasItem(i) then
                player:messageSpecial(text.CONQUEST + 60, 0, 0, item) -- You do not meet the requirements to purchase the <item>.
                player:messageSpecial(text.CONQUEST + 50, 0, 0, item) -- Due to its special nature, you can only purchase or recharge <item> once until the conquest results tally is performed. Also, you cannot purchase this item if a similar item is already in your possession.
                return false
            end
        end
    end

    -- one exp ring per conquest tally
    if xi.settings.BYPASS_EXP_RING_ONE_PER_WEEK ~= 1 and player:getCharVar("CONQUEST_RING_RECHARGE") > os.time() then
        player:messageSpecial(text.CONQUEST + 60, 0, 0, item)
        player:messageSpecial(text.CONQUEST + 50, 0, 0, item)
        return false
    end

    return true
end



-- produce supply quest mask for the nation based on current conquest standings
local function customSuppliesAvailableBitmask(player, nation)
    local mask = 2130706463

    if player:getCharVar("supplyQuest_started") == vanaDay() then
        mask = 4294967295 -- Need to wait 1 vanadiel day
    end

    for k, v in pairs(outposts) do
        if v.ki and player:hasKeyItem(v.ki) then
            mask = -1
            break
        end
    end

    if mask ~= -1 and mask ~= 4294967295 then
        for i = 0, 18 do
            if GetRegionOwner(i) == xi.nation.BEASTMEN or i == 16 or i == 17 or (i == 18 and not player:hasCompletedMission(xi.mission.log_id.COP, xi.mission.id.cop.DARKNESS_NAMED)) then
                mask = mask + 2^(i + 5)
            end
        end
    end

    return mask
end


local function customCanPurchaseItem(player, stock, pRank, guardNation, mOffset)
    -- Validate stock
    if stock == nil then
        return -1
    end

    -- validate localVar (cheat protection)
    local boughtItem = player:getLocalVar("boughtItemCP")
    player:setLocalVar("boughtItemCP", 0)
    if stock.item ~= boughtItem then
        player:messageSpecial(mOffset + 61, stock.item) -- "Your rank is too low to purchase the <item>."
        return -1
    end

    -- validate rank
    if stock.rank and pRank < stock.rank then
        player:messageSpecial(mOffset + 61, stock.item) -- "Your rank is too low to purchase the <item>."
        return -1
    end

    -- validate price
    local price = stock.cp
    if stock.rank ~= nil and player:getNation() ~= guardNation and guardNation ~= xi.nation.OTHER then
        if price <= 8000 then
            price = price * 2
        else
            price = price + 8000
        end
    end

    if player:getCP() < price then
        player:messageSpecial(mOffset + 62, 0, 0, stock.item) -- "You do not have enough conquest points to purchase the <item>."
        return -1
    end

    return price
end

m:addOverride("xi.conquest.overseerOnTrigger", function(player, npc, guardNation, guardType, guardEvent, guardRegion)
    local pNation = player:getNation()
    local zoneId = npc:getZoneID()
    local status = player:getCharVar(string.format("[GARRISON]Status_%s", zoneId))
    -- GARRISON
    if status > 0 then
        xi.garrison.onTrigger(player, npc)
    -- SUPPLY RUNS
    elseif areSuppliesRotten(player, npc, guardType) then
        -- do nothing else
    elseif guardType >= xi.conquest.guard.OUTPOST and canDeliverSupplies(player, guardNation, guardEvent, guardRegion) then
        -- do nothing else

    -- JEUNO OVERSEERS
    elseif guardType == xi.conquest.guard.CITY and guardNation == xi.nation.OTHER then
        local a1 = getArg1(player, guardNation, guardType)
        local a3 = conquestRanking()
        local a6 = getArg6(player)
        local a7 = player:getCP()

        player:startEvent(guardEvent, a1, 0, a3, 0, 0, a6, a7, 0)

    -- CITY AND FOREIGN OVERSEERS
    elseif guardType <= xi.conquest.guard.FOREIGN then
        local a1 = getArg1(player, guardNation, guardType)
        local a2 = getExForceAvailable(player, guardNation)
        local a3 = conquestRanking()
        local a4 = customSuppliesAvailableBitmask(player, guardNation)
        local a5 = player:getTeleport(guardNation)
        local a6 = getArg6(player)
        local a7 = player:getCP()
        local a8 = getExForceReward(player, guardNation)

        player:startEvent(guardEvent, a1, a2, a3, a4, a5, a6, a7, a8)

    -- OUTPOST AND BORDER OVERSEERS
    elseif guardType >= xi.conquest.guard.OUTPOST then
        local a1 = getArg1(player, guardNation, guardType)
        if a1 == 1808 then -- non-allied nation
            player:startEvent(guardEvent, a1, 0, 0, 0, 0, player:getRank(player:getNation()), 0, 0)
        else
            player:startEvent(guardEvent, a1, 0, 0x3F0000, 0, 0, getArg6(player), 0, 0)
        end
    end
end)

m:addOverride("xi.conquest.overseerOnEventUpdate", function(player, csid, option, guardNation)
    local stock = getStock(player, guardNation, option)

    if stock ~= nil then
        local pNation = player:getNation()
        local pRank   = GetNationRank(pNation)
        local u1 = 2 -- default: player is correct job and level to equip item
        local u2 = 0 -- default: player has enough CP for item
        local u3 = stock.item -- default: the item ID we're purchasing

        --[[
        if false then -- TODO: if player is a job that cannot equip selected item, set u1 to 0 here
            u1 = 0
        elseif stock.lvl > player:getMainLvl() then
            u1 = 1
        end
        ]]--

        if stock.cp > player:getCP() then
            u2 = 1
        end

        local rankCheck = true
        if guardNation ~= xi.nation.OTHER and guardNation ~= pNation and GetNationRank(guardNation) <= pRank then -- buy from other nation, must be higher ranked
            rankCheck = false
        elseif guardNation ~= xi.nation.OTHER and guardNation ~= pNation then -- buy from other nation, cannot buy items with nation rank requirement
            rankCheck = false
        end

        if rankCheck and u2 == 0 then
            player:setLocalVar("boughtItemCP", stock.item) -- set localVar for later cheat prevention
        end

        player:updateEvent(u1, u2, u3)
    end
end)

m:addOverride("xi.conquest.overseerOnEventFinish", function(player, csid, option, guardNation, guardType, guardRegion)
    local pNation  = player:getNation()
    local pRank    = player:getRank(pNation)
    local sRegion  = player:getCharVar("supplyQuest_region")
    local sOutpost = outposts[sRegion]
    local mOffset  = zones[player:getZoneID()].text.CONQUEST

    -- SIGNET
    if option == 1 then
        local duration = (pRank + GetNationRank(pNation) + 3) * 3600
        player:delStatusEffectsByFlag(xi.effectFlag.INFLUENCE, true)
        player:addStatusEffect(xi.effect.SIGNET, 0, 0, duration)
        player:messageSpecial(mOffset + 1) -- "You've received your nation's Signet!"

        if player:getEminenceProgress(3367) then
            xi.roe.onRecordTrigger(player, 3367) -- Complete Weekly Signet, brb objective.  This might be able to move to a status effect trigger
        end

    -- BEGIN SUPPLY RUN
    elseif option >= 65541 and option <= 65565 and guardType <= xi.conquest.guard.FOREIGN then
        local region = option - 65541
        local outpost = outposts[region]
        if outpost ~= nil then
            npcUtil.giveKeyItem(player, outpost.ki)
            player:setCharVar("supplyQuest_started", vanaDay())
            player:setCharVar("supplyQuest_region", region)
            player:setCharVar("supplyQuest_fresh", getConquestTally())
        end

    -- FINISH SUPPLY RUN
    elseif
        option == 2 and
        guardType >= xi.conquest.guard.OUTPOST and
        sRegion == guardRegion and
        sOutpost ~= nil and
        player:hasKeyItem(sOutpost.ki)
    then
        player:delKeyItem(sOutpost.ki)
        player:addCP(sOutpost.cp)
        player:messageSpecial(mOffset) -- "You've earned conquest points!"
        player:setCharVar("supplyQuest_started", 0)
        player:setCharVar("supplyQuest_region", 0)
        player:setCharVar("supplyQuest_fresh", 0)

        if not player:hasTeleport(pNation, sRegion + 5) then
            player:addTeleport(pNation, sRegion + 5)
        end

    -- SET HOMEPOINT
    elseif option == 4 then
        if player:delGil(setHomepointFee(player, guardNation)) then
            player:setHomePoint()
            player:messageSpecial(mOffset + 94) -- "Your home point has been set."
        else
            player:messageSpecial(mOffset + 95) -- "You do not have enough gil to set your home point here."
        end

    -- PURCHASE CP ITEM
    elseif option >= 32768 and option <= 32944 then
        local stock = getStock(player, guardNation, option)
        local price = customCanPurchaseItem(player, stock, pRank, guardNation, mOffset)

        if price < 0 then
            return
        end

        -- validate exp rings
        if option >= 32933 and option <= 32935 and not canBuyExpRing(player, stock.item) then
            return
        end

        -- make sale
        if npcUtil.giveItem(player, stock.item) then
            player:delCP(price)
            if option >= 32933 and option <= 32935 then
                player:setCharVar("CONQUEST_RING_RECHARGE", getConquestTally())
            end
        end
    end
end)


return m
