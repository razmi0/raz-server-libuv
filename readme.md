# Features Not Handled by the Server

## 4. Keep-Alive / Connection Persistence

No parsing of Connection: keep-alive

Closes the connection after each response

## 5. TLS/SSL (HTTPS)

No support for TLS via uv_tls or any other means

Only supports raw TCP via uv.new_tcp()

## 6. Backpressure / Flow Control

No buffer monitoring or pause/resume logic during writes

Risk of memory pressure with large responses or slow clients

## 7. Timeouts / Rate Limiting

No handling of:

Idle client timeouts

Read/write timeouts

Rate limiting (e.g. too many requests/sec)

## 8. Robust Error Recovery

Simple pcall around app:_run() only

All errors result in connection close

No graceful degradation or retries

## 9. Request Body Handling

No logic for parsing:

Content-Length

Chunked encoding

Multipart/form-data

Assumes full request fits in a single chunk

## 10. Logging, Access Control, and Security Headers

No access log

No IP filtering / authentication

No automatic security headers (CORS, CSP, etc.)

## 11. Concurrency / Multi-core Scaling

Single-process uv.run()

No process clustering or thread pools
