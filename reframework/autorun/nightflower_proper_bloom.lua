local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local next = next

-- local kami = require("_kami_utilities")

local GM000_153 = sdk.find_type_definition("app.GimmickDef.FIND_CONTEXT_TYPE"):get_field("GM000_153"):get_data()
local TO_ENABLE = sdk.find_type_definition("ace.GimmickDef.BASE_STATE"):get_field("TO_ENABLE"):get_data()
local MAIN = sdk.find_type_definition("app.EnvironmentManager.FIELD_DATA_LAYER"):get_field("MAIN"):get_data()

local collected_gm = {
    items = {},
    is_empty = true,
    add = function (self, item)
        self.items[item] = true
        self:_update_empty()
    end,
    clear = function (self)
        self.items = {}
        self:_update_empty()
    end,
    _update_empty = function (self)
        self.is_empty = (next(self.items) == nil)
    end
}

local function is_daytime(count)
    if count >= 350 and count < 2050 then
        return true
    end
    return false
end

local function is_game_loaded()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if player_manager == nil then return false end

    local master_player = player_manager:call("getMasterPlayer()")
    if master_player == nil then return false end

    local character = master_player:call("get_Character()")
    if character == nil then return false end

    return true
end

local function get_active_layer()
    local environment_manager = sdk.get_managed_singleton("app.EnvironmentManager")
    local active_layer = environment_manager:call("getActiveTimeLayer()")
    return active_layer
end

local function get_layer_time()
    local environment_manager = sdk.get_managed_singleton("app.EnvironmentManager")
    local active_layer = environment_manager:call("getActiveTimeLayer()")
    local option = environment_manager:call("getOption(app.EnvironmentManager.FIELD_DATA_LAYER, System.Boolean, System.Boolean, System.Boolean, System.Boolean)", active_layer, false, false, false, false)
    local time_data = environment_manager:call("getTimeData(System.UInt32)", option)
    local count = time_data:call("get_Count()")
    return count
end

local function get_active_moon()
    local environment_manager = sdk.get_managed_singleton("app.EnvironmentManager")
    local moon_controller = environment_manager:get_field("_MoonController")
    local moon_idx = moon_controller:call("getActiveMoonData()"):call("get_MoonIdx()")
    return moon_idx
end

local function try_bloom_flower()
    if not is_game_loaded() then
        -- print("Game is not loaded.")
        return
    end

    if is_daytime(get_layer_time()) then
        -- print("It is not at night.")
        return
    end

    if get_active_moon() ~= 0 then
        -- print("It is not full moon currently.")
        return
    end

    local gimmick_manager = sdk.get_managed_singleton("app.GimmickManager")
    local gm_list = gimmick_manager:get_field("_FindGimmickContext"):call("getGimmickList(app.GimmickDef.FIND_CONTEXT_TYPE)", GM000_153):get_field("_items")

    if gm_list then
        for _, gm_ctx in pairs(gm_list) do
            if gm_ctx then
                local gimmick = gm_ctx:call("get_Gimmick()")
                local gm_unique_id = gimmick:call("get_UniqueIndex()")
                if get_active_layer() ~= MAIN or not collected_gm.items[gm_unique_id] then
                    gm_ctx:call("changeState(ace.GimmickDef.BASE_STATE)", TO_ENABLE)
                    -- print("Enable: " .. gm_unique_id)
                end
            end
        end
    end
end

-- re.on_draw_ui(function()
--     if imgui.tree_node("Nightflower Proper Bloom") then
--         if imgui.button("try_bloom_flower") then
--             try_bloom_flower()
--         end
--         if imgui.button("get_active_moon") then
--             print("Moon: " .. get_active_moon())
--         end
--         if imgui.button("get_layer_time") then
--             print("Time: " .. get_layer_time())
--         end
--         imgui.tree_pop()
--     end
-- end)

sdk.hook(sdk.find_type_definition("app.EnemyManager"):get_method("onStageLoadEnd(app.FieldDef.STAGE)"),
    function(args)
        -- print("onStageLoadEnd")
        try_bloom_flower()
    end,
    function(retval)
        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.Gm000_153"):get_method("successEvent()"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if not this then return end

        local gimmick = this:get_field("_ContextHolder"):call("get_Gimmick()")
        local gm_unique_id = gimmick:call("get_UniqueIndex()")

        if get_active_layer() == MAIN then
            collected_gm:add(gm_unique_id)
            -- print("Collected: " .. gm_unique_id)
        end
    end,
    function(retval)
        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.FacilityManager"):get_method("executeChangeTime()"),
    function(args)
        collected_gm:clear()
        -- print("CLEAR")
    end,
    function(retval)
        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.cGameCountData_Main"):get_method("update(System.Single)"),
    function(args)
        if collected_gm.is_empty then
            return
        end
        local this = sdk.to_managed_object(args[2])
        if not this then return end
        if is_daytime(this:get_field("_Count")) then
            collected_gm:clear()
            -- print("CLEAR")
        end
    end,
    function(retval)
        return retval
    end
)