local Keymap = { grid = {} }

function Keymap.grid.poly()
    local held = {}
    local is_releasing = false

    local que = {}
    
    local _momentaries = Grid.momentaries()
        
    return function(props)
        local keymap = props.keymap

        props.state = crops.of_variable(keymap.keys, keymap.set_keys)

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
                    elseif #held > 2 then
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
    local _momentaries = Grid.momentaries()
    local _integer = Grid.integer()

    return function(props)
        local keymap = props.keymap

        if crops.mode == 'input' then
            props.state = crops.of_variable(keymap.keys, keymap.set_keys)
            _momentaries(props)
        elseif crops.mode == 'redraw' then
            props.state = crops.of_variable(keymap.index)
            if keymap.gate > 0 then
                _integer(props)
            end
        end
    end
end

return Keymap
