--- experimental voice allocation module
-- fork by @andrew
-- @module lib.voice

-- (voice) Slot class
local Slot = {}
Slot.__index = Slot

--TODO: slot.disabled
--      when disabled, slot cannot be allocated/stolen
function Slot.new(pool, id)
    local o = setmetatable({}, Slot)
	o.pool = pool
	o.id = id
	o.active = false
	o.on_release = nil
	o.on_steal = nil
	return o
end

-- LRU allocation class
local LRU = {}
LRU.__index = LRU

function LRU.new(polyphony, slots)
	local o = setmetatable({}, LRU)
	o.slots = slots
	o.count = 0
	for _, s in pairs(slots) do
		s.n = 0    -- yuck: add field to slot
	end
	return o
end

function LRU:next()
	local count = self.count + 1
	local next = self.slots[1]
	local free = nil

	self.count = count

	for _, slot in pairs(self.slots) do
		if not slot.active then
			if free == nil or slot.n < free.n then
				free = slot
			end
		elseif slot.n < next.n then
			next = slot
		end
	end

	-- choose free voice if possible
	if free then next = free end
	next.n = count
	return next
end

-- Voice class
local Voice = {}
Voice.__index = Voice

--- create a new Voice
-- @tparam number polyphony
-- @treturn Voice
function Voice.new(polyphony)
	local o = setmetatable({}, Voice)
	o.polyphony = polyphony
	o.mode = mode
	o.will_steal = nil      -- event callback
	o.will_release = nil     -- event callback
	o.pairings = {}

	local slots = {}
	for id = 1, polyphony do
		slots[id] = Slot.new(o, id)
	end
	
    o.style = LRU.new(polyphony, slots)

	return o
end

--- get next available voice Slot from pool, stealing an active slot if needed
function Voice:get()
	local slot = self.style:next()
	if slot.active then
		if self.will_steal then self.will_steal(slot) end

		-- ack; nuke any existing pairings
		for key, value in pairs(self.pairings) do
			if value == slot then
				self.pairings[key] = nil
				break
			end
		end

		if slot.on_steal then 
			slot.on_steal(slot)
		elseif slot.on_release then
			slot.on_release(slot)
		end
	end
	slot.active = true
	return slot
end

--- return voice slot to pool
-- @param slot : a Slot obtained from get()
function Voice:release(slot)
	if slot.pool == self then
		if self.will_release then self.will_release(slot) end
		if slot.on_release then slot.on_release(slot) end
		slot.active = false
	else
		print("voice slot: ", slot, "does not belong to pool: ", self)
	end
end

--- push
function Voice:push(key)
    local slot = self:get()

	self.pairings[key] = slot

    return slot.id
end

--- pop
function Voice:pop(key)
	local slot = self.pairings[key]
	self.pairings[key] = nil

    self:release(slot)

    return slot.id
end

--TODO: untested

function Voice:disable_slot(id)
    local slot = self.style.slots[id]
    self:release(slot)
    slot.disabled = true

    local key = nil
    for k,v in pairs(self.pairings) do
        if v == slot then
            self.pairings[k] = nil
            break
        end
    end
end

function Voice:enable_slot(id)
    local slot = self.style.slots[id]
    slot.disabled = false
end

return Voice
