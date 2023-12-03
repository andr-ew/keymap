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

function poly:clear()
    self.set_keys_silent({})
    self.pattern:stop()
end

local mono = {}
mono.__index = mono

function mono.new(args)
    local self = {}
    setmetatable(self, mono)
        
    self.action = args.action or function(idx, gt) end
    self.size = args.size or 128
    self.pattern = args.pattern
        
    self.keys = {}
    self.index = 1
    self.gate = 0

    local function set_idx_gate(idx, gt)
        self.index = idx
        self.gate = gt
        self.action(self.index, self.gate)

        crops.dirty.grid = true
        crops.dirty.screen = true
    end
    
    args.pattern.process = function(e) set_idx_gate(table.unpack(e)) end
    local set_idx_gate_wr = function(idx, gt)
        set_idx_gate(idx, gt)
        args.pattern:watch({ idx, gt })
    end

    local set_states = function(value)
        local gt = 0
        local idx = self.index 

        for i = args.size, 1, -1 do
            local v = value[i] or 0

            if v > 0 then
                gt = 1
                idx = i
                break;
            end
        end

        self.keys = value
        set_idx_gate_wr(idx, gt)
    end

    local clear = function() set_idx_gate(self.index, 0) end
    local snapshot = function()
        if self.gate > 0 then set_idx_gate_wr(self.index, self.gate) end
    end

    local handlers = {
        pre_clear = clear,
        pre_rec_stop = snapshot,
        post_rec_start = snapshot,
        post_stop = clear,
    }

    args.pattern:set_all_hooks(handlers)
    
    self.set_keys = set_states
    self.set_idx_gate_silent = set_idx_gate

    return self
end

function mono:clear()
    self.keys = {}
    self.set_idx_gate_silent(self.index, 0)

    self.pattern:stop()
end

keymap.poly = poly
keymap.mono = mono

return keymap
