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
        
    local set_keys = function(value)
        local news, olds = value, self.keys

        for i = 1, self.size do
            local new = news[i] or 0
            local old = olds[i] or 0

            if new==1 and old==0 then self.action_on(i)
            elseif new==0 and old==1 then self.action_off(i) end
        end

        self.keys = news
        crops.dirty.grid = true
        crops.dirty.screen = true
    end

    self.pattern.process = set_keys

    local set_keys_wr = function(value)
        set_keys(value)
        self.pattern:watch(value)
    end

    local clear = function() set_keys({}) end
    local snapshot = function()
        local has_keys = false
        for i = 1, self.size do if (self.keys[i] or 0) > 0 then  
            has_keys = true; break
        end end

        if has_keys then set_keys_wr(self.keys) end
    end

    local handlers = {
        pre_clear = clear,
        pre_rec_stop = snapshot,
        post_rec_start = snapshot,
        post_stop = clear,
    }

    self.pattern:set_all_hooks(handlers)

    self.set_keys = set_keys_wr
    self.set_keys_silent = set_keys

    return self
end

function poly:get()
    return self.keys
end

function poly:set(new)
    self.set_keys(new)
end

function poly:clear()
    self.set_keys_silent({})
    self.pattern:stop()
end

function poly:set_latch() end

function poly:get_state()
    return { self.keys, self.set_keys }
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
    self.set_index_gate_silent = set_index_gate

    return self
end

function mono:get()
    return self.index_gate
end

function mono:set(new)
    self.set_index_gate(new)
end

function mono:clear()
    self.set_index_gate_silent({ self.index_gate[1], 0 })

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
