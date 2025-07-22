function HTTP413(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(413)
    ctx.res:setBody("413 Content Too Large")
    return ctx.res
end

local raw =
"HTTP/1.1 413 Content Too Large\r\nContent-Type: text/plain\r\nContent-Length: 22\r\n\r\n413 Content Too Large\r\n"

return HTTP413, raw
