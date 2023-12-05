local Keymap = { grid = {} }

function Keymap.grid.poly()
    local held = {}
    local is_releasing = false

    local que = {}
    
    local _momentaries = Grid.momentaries()
        
    return function(props)
        if crops.mode == 'input' then
            local x, y, z = table.unpack(crops.args) 
            local idx = Grid.util.xy_to_index(props, x, y)

            if idx then 
                local latch = props.mode == 'latch'

                local function chord_add(idx) 
                    que[idx] = 1
                end
                local function chord_release()
                    if latch then crops.set_state(props.state, que) end
                    que = {}
                end
                local function tap(idx) if latch then 
                    local old = crops.get_state_at(props.state, idx) or 0
                    crops.set_state_at(props.state, idx, old ~ 1)
                end end

                if z==1 then
                    table.insert(held, idx)

                    if #held == 3 then
                        for _,iidx in ipairs(held) do chord_add(iidx) end
                    elseif #held > 3 then
                        chord_add(idx)
                    end
                elseif z==0 then
                    if #held < 2 and is_releasing then
                        chord_release() 
                        is_releasing = false
                    elseif #held > 2 then
                        is_releasing = true
                    else
                        tap(idx)
                    end
                    
                    table.remove(held, tab.key(held, idx))
                end

                if not latch then _momentaries(props) end
            end
        else
            _momentaries(props)
        end
    end
end

function Keymap.grid.mono()
    local held = {}

    return function(props)
        if crops.device == 'grid' then
            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)
                local n = Grid.util.xy_to_index(props, x, y)

                if n then
                    if z==1 then
                        table.insert(held, n)
                    elseif z==0 then
                        table.remove(held, tab.key(held, n))
                    end

                    if #held > 0 then
                        crops.set_state(props.state, { held[#held], 1 })
                    else
                        local gate = props.mode == 'latch' and 1 or 0
                        crops.set_state_at(props.state, 2, gate)
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler

                local index, gate = table.unpack(crops.get_state(props.state) or { 1, 0 })
                local lvl = props.levels[gate + 1]

                if lvl > 0 then
                    local x, y = Grid.util.index_to_xy(props, index)
                    g:led(x, y, lvl)
                end
            end
        end
    end
end

return Keymap
