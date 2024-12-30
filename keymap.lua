local keymap = {}

local keymap = {}

local poly = {}
poly.__index = poly

function poly.new(args)
    local self = {}
    setmetatable(self, poly)
        
    self.action_on = args.action_on or function(idx) end
    self.action_off = args.action_off or function(idx) end
    self.size = args.size or 128
    self.pattern = args.pattern

    self.keys = {}
        
    local set_keys = function(data)
        local value, silent = table.unpack(data)
        local news, olds = value, self.keys

        --TODO: optimization - only need to loop once for human input
        -- for i = 1, self.size do
        --     local new = news[i] or 0
        --     local old = olds[i] or 0

        --     if new==1 and old==0 then self.action_on(i, silent)
        --     elseif new==0 and old==1 then self.action_off(i, silent) end
        -- end
        for i = 1, self.size do
            local new = news[i] or 0
            local old = olds[i] or 0

            if new==0 and old==1 then self.action_off(i, silent) end
        end
        for i = 1, self.size do
            local new = news[i] or 0
            local old = olds[i] or 0

            if new==1 and old==0 then self.action_on(i, silent) end
        end

        self.keys = news
        crops.dirty.grid = true
        crops.dirty.screen = true
    end

    self.pattern.process = set_keys

    local set_keys_wr = function(silent, value)
        local data = { value, silent }
        set_keys(data)
        self.pattern:watch(data)
    end

    local set_keys_bypass = function(silent, value) set_keys({ value, silent }) end

    local clear = function() set_keys_bypass({}) end
    local snapshot = function()
        local has_keys = false
        for i = 1, self.size do if (self.keys[i] or 0) > 0 then  
            has_keys = true; break
        end end

        if has_keys then set_keys_wr(false, self.keys) end
    end

    local handlers = {
        pre_clear = clear,
        pre_rec_stop = snapshot,
        post_rec_start = snapshot,
        post_stop = clear,
    }

    self.pattern:set_all_hooks(handlers)

    self.set_keys = set_keys_wr
    self.set_keys_bypass = set_keys_bypass 

    return self
end

function poly:get()
    return self.keys
end

function poly:set(new, silent, watch)
    if watch == false then self.set_keys_bypass(silent, new)
    else self.set_keys(silent, new) end
end

function poly:clear(silent)
    self.set_keys_bypass(silent, {})
    self.pattern:stop()
end

function poly:set_latch() end

function poly:get_state(silent)
    return { self.keys, self.set_keys, silent }
end

local mono = {}
mono.__index = mono

function mono.new(args)
    local self = {}
    setmetatable(self, mono)
        
    self.action = args.action or function(idx, gt) end
    self.size = args.size or 128
    self.pattern = args.pattern
        
    self.index_gate = { 1, 0 }

    local function set_index_gate(new)
        self.index_gate = new
        self.action(table.unpack(new))

        crops.dirty.grid = true
        crops.dirty.screen = true
    end
    
    args.pattern.process = set_index_gate 
    local set_index_gate_wr = function(new)
        set_index_gate(new)
        args.pattern:watch(new)
    end

    --TODO: move this logic to ./ui.lua
    -- local set_states = function(value)
    --     local gt = 0
    --     local idx = self.index 

    --     for i = args.size, 1, -1 do
    --         local v = value[i] or 0

    --         if v > 0 then
    --             gt = 1
    --             idx = i
    --             break;
    --         end
    --     end

    --     self.keys = value
    --     set_idx_gate_wr(idx, gt)
    -- end

    local clear = function() set_index_gate({ self.index_gate[1], 0 }) end
    local snapshot = function()
        if self.index_gate[2] > 0 then 
            set_index_gate_wr({ self.index_gate[1], self.index_gate[2] }) 
        end
    end

    local handlers = {
        pre_clear = clear,
        pre_rec_stop = snapshot,
        post_rec_start = snapshot,
        post_stop = clear,
    }

    args.pattern:set_all_hooks(handlers)
    
    self.set_index_gate = set_index_gate_wr
    self.set_index_gate_bypass = set_index_gate

    return self
end

function mono:get()
    return self.index_gate
end

function mono:set(new)
    self.set_index_gate(new)
end

function mono:clear()
    self.set_index_gate_bypass({ self.index_gate[1], 0 })

    self.pattern:stop()
end

function mono:set_latch(latch)
    self.set_index_gate({ self.index_gate[1], latch and 1 or 0 })
end

function mono:get_state()
    return { self.index_gate, self.set_index_gate }
end

keymap.poly = poly
keymap.mono = mono

return keymap
