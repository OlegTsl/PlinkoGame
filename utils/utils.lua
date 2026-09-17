local M = {}

M.T = {
    Nil      = "nil",
    Boolean  = "boolean",
    Number   = "number",
    String   = "string",
    Table    = "table",
    Function = "function",
    Thread   = "thread",
    Userdata = "userdata",
}

function M.is_type(value, expected, name)
    assert(type(value) == expected, name .. " must be a " .. expected)
    return value
end

return M