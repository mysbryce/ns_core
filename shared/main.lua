--- Ref: https://github.com/overextended/ox_lib/blob/master/imports/class/shared.lua
--- Ensure the given argument or property has a valid type, otherwise throwing an error.
--- @param id number | string
--- @param var any
--- @param expected type
local function assertType(id, var, expected)
    local received = type(var)

    if received ~= expected then
        error(("expected %s %s to have type '%s' (received %s)")
            :format(type(id) == 'string' and 'field' or 'argument', id, expected, received), 3)
    end

    if expected == 'table' and table.type(var) ~= 'hash' then
        error(("expected argument %s to have table.type 'hash' (received %s)")
            :format(id, table.type(var)), 3)
    end

    return true
end

exports('assertType', assertType)
