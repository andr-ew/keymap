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
