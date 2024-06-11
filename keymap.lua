local keymap = {}

keymap.allocator = {}
keymap.allocator.__index = keymap.allocator

function keymap.allocator.new(args)
    local self = {}
    setmetatable(self, keymap.allocator)
        
    -- self.action_on = args.action_on or function(idx) end
    -- self.action_off = args.action_off or function(idx) end
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

function keymap.allocator:get()
    return self.keys
end

function keymap.allocator:set(new)
    self.set_keys(new)
end

function keymap.allocator:clear()
    self.set_keys_silent({})
    self.pattern:stop()
end

function keymap.allocator:set_latch() end

function keymap.allocator:get_state()
    return { self.keys, self.set_keys }
end

return keymap
