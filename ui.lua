local Keymap = { grid = {} }

function Keymap.grid.poly()
   local _momentaries = Grid.momentaries()
   local _toggles = Grid.toggles()

   return function(props)
        local keymap = props.keymap

        props.state = crops.of_variable(keymap.keys, keymap.set_keys)

        if props.mode == 'latch' then
            _toggles(props)
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

        local momentaries_props = {}
        local integer_props = {}
        for k,v in pairs(props) do 
            momentaries_props[k] = props[k] 
            integer_props[k] = props[k] 
        end

        momentaries_props.state = crops.of_variable(keymap.keys, keymap.set_keys)
        integer_props.state = crops.of_variable(keymap.index)

        if crops.mode == 'input' then
            _momentaries(momentaries_props)
        elseif crops.mode == 'redraw' then
            if keymap.gate > 0 then
                _integer(integer_props)
            end
        end
    end
end

return Keymap
