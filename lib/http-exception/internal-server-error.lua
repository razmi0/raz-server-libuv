function HTTP500(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(500)
    ctx.res:setBody("500 Internal Server Error")
    return ctx.res
end

local raw =
"HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 23\r\n\r\n500 Internal Server Error"

return HTTP500, raw
