-- Creating a simple setInterval wrapper
local function setInterval(interval, callback)
    local timer = require("luv").new_timer()
    timer:start(interval, interval, function()
        callback()
    end)
    return timer
end

return setInterval
