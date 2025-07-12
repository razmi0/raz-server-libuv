-- And clearInterval
local function clearInterval(timer)
    timer:stop()
    timer:close()
end
return clearInterval
