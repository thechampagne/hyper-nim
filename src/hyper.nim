# Copyright 2023 XXIV
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
const
  ##  Return in iter functions to continue iterating.
  HYPER_ITER_CONTINUE* = 0
  ##  Return in iter functions to stop iterating.
  HYPER_ITER_BREAK* = 1
  ##  An HTTP Version that is unspecified.
  HYPER_HTTP_VERSION_NONE* = 0
  ##  The HTTP/1.0 version.
  HYPER_HTTP_VERSION_1_0* = 10
  ##  The HTTP/1.1 version.
  HYPER_HTTP_VERSION_1_1* = 11
  ##  The HTTP/2 version.
  HYPER_HTTP_VERSION_2* = 20
  ##  Sentinel value to return from a read or write callback that the operation is pending.
  HYPER_IO_PENDING* = 4294967295'i64
  ##  Sentinel value to return from a read or write callback that the operation has errored.
  HYPER_IO_ERROR* = 4294967294'i64
  ##  Return in a poll function to indicate it was ready.
  HYPER_POLL_READY* = 0
  ##  Return in a poll function to indicate it is still pending.
  ##  The passed in `hyper_waker` should be registered to wake up the task at
  ##  some later point.
  HYPER_POLL_PENDING* = 1
  ##  Return in a poll function indicate an error.
  HYPER_POLL_ERROR* = 3
  

type
  ##  A return code for many of hyper's methods.
  hyper_code* = enum
    ##    All is well.
    HYPERE_OK,
    ##    General error, details in the `hyper_error *`.
    HYPERE_ERROR,
    ##    A function argument was invalid.
    HYPERE_INVALID_ARG,
    ##    The IO transport returned an EOF when one wasn't expected.
    ##    This typically means an HTTP request or response was expected, but the
    ##    connection closed cleanly without sending (all of) it.
    HYPERE_UNEXPECTED_EOF,
    ##    Aborted by a user supplied callback.
    HYPERE_ABORTED_BY_CALLBACK,
    ##    An optional hyper feature was not enabled.
    HYPERE_FEATURE_NOT_ENABLED,
    ##    The peer sent an HTTP message that could not be parsed.
    HYPERE_INVALID_PEER_MESSAGE
  ##  A descriptor for what type a `hyper_task` value is.
  hyper_task_return_type* = enum
    ##    The value of this task is null (does not imply an error).
    HYPER_TASK_EMPTY,
    ##    The value of this task is `hyper_error *`.
    HYPER_TASK_ERROR,
    ##    The value of this task is `hyper_clientconn *`.
    HYPER_TASK_CLIENTCONN,
    ##    The value of this task is `hyper_response *`.
    HYPER_TASK_RESPONSE,
    ##    The value of this task is `hyper_buf *`.
    HYPER_TASK_BUF
  ##  A streaming HTTP body.
  hyper_body* {.bycopy.} = object
  ##  A buffer of bytes that is sent or received on a `hyper_body`.
  hyper_buf* {.bycopy.} = object
  ##  An HTTP client connection handle.
  ##  These are used to send a request on a single connection. It's possible to
  ##  send multiple requests on a single connection, such as when HTTP/1
  ##  keep-alive or HTTP/2 is used.
  hyper_clientconn* {.bycopy.} = object
  ##  An options builder to configure an HTTP client connection.
  hyper_clientconn_options* {.bycopy.} = object
  ##  An async context for a task that contains the related waker.
  hyper_context* {.bycopy.} = object
  ##  A more detailed error object returned by some hyper functions.
  hyper_error* {.bycopy.} = object
  ##  A task executor for `hyper_task`s.
  hyper_executor* {.bycopy.} = object
  ##  An HTTP header map.
  ##  These can be part of a request or response.
  hyper_headers* {.bycopy.} = object
  ##  An IO object used to represent a socket or similar concept.
  hyper_io* {.bycopy.} = object
  ##  An HTTP request.
  hyper_request* {.bycopy.} = object
  ##  An HTTP response.
  hyper_response* {.bycopy.} = object
  ##  An async task.
  hyper_task* {.bycopy.} = object
  ##  A waker that is saved and used to waken a pending task.
  hyper_waker* {.bycopy.} = object
  hyper_body_foreach_callback* = proc (a1: pointer, a2: ptr hyper_buf): cint {.cdecl.}
  hyper_body_data_callback* = proc (a1: pointer, a2: ptr hyper_context,
                                 a3: ptr ptr hyper_buf): cint {.cdecl.}
  hyper_request_on_informational_callback* = proc (a1: pointer,
      a2: ptr hyper_response) {.cdecl.}
  hyper_headers_foreach_callback* = proc (a1: pointer, a2: ptr uint8, a3: csize_t,
                                       a4: ptr uint8, a5: csize_t): cint {.cdecl.}
  hyper_io_read_callback* = proc (a1: pointer, a2: ptr hyper_context, a3: ptr uint8,
                               a4: csize_t): csize_t {.cdecl.}
  hyper_io_write_callback* = proc (a1: pointer, a2: ptr hyper_context, a3: ptr uint8,
                                a4: csize_t): csize_t {.cdecl.}

##
##  Returns a static ASCII (null terminated) string of the hyper version.
##

proc hyper_version*(): cstring {.importc.}
##
##  Create a new "empty" body.
##
##  If not configured, this body acts as an empty payload.
##

proc hyper_body_new*(): ptr hyper_body {.importc.}
##
##  Free a `hyper_body *`.
##

proc hyper_body_free*(body: ptr hyper_body) {.importc.}
##
##  Return a task that will poll the body for the next buffer of data.
##
##  The task value may have different types depending on the outcome:
##
##  - `HYPER_TASK_BUF`: Success, and more data was received.
##  - `HYPER_TASK_ERROR`: An error retrieving the data.
##  - `HYPER_TASK_EMPTY`: The body has finished streaming data.
##
##  This does not consume the `hyper_body *`, so it may be used to again.
##  However, it MUST NOT be used or freed until the related task completes.
##

proc hyper_body_data*(body: ptr hyper_body): ptr hyper_task {.importc.}
##
##  Return a task that will poll the body and execute the callback with each
##  body chunk that is received.
##
##  The `hyper_buf` pointer is only a borrowed reference, it cannot live outside
##  the execution of the callback. You must make a copy to retain it.
##
##  The callback should return `HYPER_ITER_CONTINUE` to continue iterating
##  chunks as they are received, or `HYPER_ITER_BREAK` to cancel.
##
##  This will consume the `hyper_body *`, you shouldn't use it anymore or free it.
##

proc hyper_body_foreach*(body: ptr hyper_body, `func`: hyper_body_foreach_callback,
                        userdata: pointer): ptr hyper_task {.importc.}
##
##  Set userdata on this body, which will be passed to callback functions.
##

proc hyper_body_set_userdata*(body: ptr hyper_body, userdata: pointer) {.importc.}
##
##  Set the data callback for this body.
##
##  The callback is called each time hyper needs to send more data for the
##  body. It is passed the value from `hyper_body_set_userdata`.
##
##  If there is data available, the `hyper_buf **` argument should be set
##  to a `hyper_buf *` containing the data, and `HYPER_POLL_READY` should
##  be returned.
##
##  Returning `HYPER_POLL_READY` while the `hyper_buf **` argument points
##  to `NULL` will indicate the body has completed all data.
##
##  If there is more data to send, but it isn't yet available, a
##  `hyper_waker` should be saved from the `hyper_context *` argument, and
##  `HYPER_POLL_PENDING` should be returned. You must wake the saved waker
##  to signal the task when data is available.
##
##  If some error has occurred, you can return `HYPER_POLL_ERROR` to abort
##  the body.
##

proc hyper_body_set_data_func*(body: ptr hyper_body,
                              `func`: hyper_body_data_callback) {.importc.}
##
##  Create a new `hyper_buf *` by copying the provided bytes.
##
##  This makes an owned copy of the bytes, so the `buf` argument can be
##  freed or changed afterwards.
##
##  This returns `NULL` if allocating a new buffer fails.
##

proc hyper_buf_copy*(buf: ptr uint8, len: csize_t): ptr hyper_buf {.importc.}
##
##  Get a pointer to the bytes in this buffer.
##
##  This should be used in conjunction with `hyper_buf_len` to get the length
##  of the bytes data.
##
##  This pointer is borrowed data, and not valid once the `hyper_buf` is
##  consumed/freed.
##

proc hyper_buf_bytes*(buf: ptr hyper_buf): ptr uint8 {.importc.}
##
##  Get the length of the bytes this buffer contains.
##

proc hyper_buf_len*(buf: ptr hyper_buf): csize_t {.importc.}
##
##  Free this buffer.
##

proc hyper_buf_free*(buf: ptr hyper_buf) {.importc.}
##
##  Starts an HTTP client connection handshake using the provided IO transport
##  and options.
##
##  Both the `io` and the `options` are consumed in this function call.
##
##  The returned `hyper_task *` must be polled with an executor until the
##  handshake completes, at which point the value can be taken.
##

proc hyper_clientconn_handshake*(io: ptr hyper_io,
                                options: ptr hyper_clientconn_options): ptr hyper_task {.importc.}
##
##  Send a request on the client connection.
##
##  Returns a task that needs to be polled until it is ready. When ready, the
##  task yields a `hyper_response *`.
##

proc hyper_clientconn_send*(conn: ptr hyper_clientconn, req: ptr hyper_request): ptr hyper_task {.importc.}
##
##  Free a `hyper_clientconn *`.
##

proc hyper_clientconn_free*(conn: ptr hyper_clientconn) {.importc.}
##
##  Creates a new set of HTTP clientconn options to be used in a handshake.
##

proc hyper_clientconn_options_new*(): ptr hyper_clientconn_options {.importc.}
##
##  Set the whether or not header case is preserved.
##
##  Pass `0` to allow lowercase normalization (default), `1` to retain original case.
##

proc hyper_clientconn_options_set_preserve_header_case*(
    opts: ptr hyper_clientconn_options, enabled: cint) {.importc.}
##
##  Set the whether or not header order is preserved.
##
##  Pass `0` to allow reordering (default), `1` to retain original ordering.
##

proc hyper_clientconn_options_set_preserve_header_order*(
    opts: ptr hyper_clientconn_options, enabled: cint) {.importc.}
##
##  Free a `hyper_clientconn_options *`.
##

proc hyper_clientconn_options_free*(opts: ptr hyper_clientconn_options) {.importc.}
##
##  Set the client background task executor.
##
##  This does not consume the `options` or the `exec`.
##

proc hyper_clientconn_options_exec*(opts: ptr hyper_clientconn_options,
                                   exec: ptr hyper_executor) {.importc.}
##
##  Set the whether to use HTTP2.
##
##  Pass `0` to disable, `1` to enable.
##

proc hyper_clientconn_options_http2*(opts: ptr hyper_clientconn_options,
                                    enabled: cint): hyper_code {.importc.}
##
##  Set the whether to include a copy of the raw headers in responses
##  received on this connection.
##
##  Pass `0` to disable, `1` to enable.
##
##  If enabled, see `hyper_response_headers_raw()` for usage.
##

proc hyper_clientconn_options_headers_raw*(opts: ptr hyper_clientconn_options,
    enabled: cint): hyper_code {.importc.}
##
##  Frees a `hyper_error`.
##

proc hyper_error_free*(err: ptr hyper_error) {.importc.}
##
##  Get an equivalent `hyper_code` from this error.
##

proc hyper_error_code*(err: ptr hyper_error): hyper_code {.importc.}
##
##  Print the details of this error to a buffer.
##
##  The `dst_len` value must be the maximum length that the buffer can
##  store.
##
##  The return value is number of bytes that were written to `dst`.
##

proc hyper_error_print*(err: ptr hyper_error, dst: ptr uint8, dst_len: csize_t): csize_t {.importc.}
##
##  Construct a new HTTP request.
##

proc hyper_request_new*(): ptr hyper_request {.importc.}
##
##  Free an HTTP request if not going to send it on a client.
##

proc hyper_request_free*(req: ptr hyper_request) {.importc.}
##
##  Set the HTTP Method of the request.
##

proc hyper_request_set_method*(req: ptr hyper_request, `method`: ptr uint8,
                              method_len: csize_t): hyper_code {.importc.}
##
##  Set the URI of the request.
##
##  The request's URI is best described as the `request-target` from the RFCs. So in HTTP/1,
##  whatever is set will get sent as-is in the first line (GET $uri HTTP/1.1). It
##  supports the 4 defined variants, origin-form, absolute-form, authority-form, and
##  asterisk-form.
##
##  The underlying type was built to efficiently support HTTP/2 where the request-target is
##  split over :scheme, :authority, and :path. As such, each part can be set explicitly, or the
##  type can parse a single contiguous string and if a scheme is found, that slot is "set". If
##  the string just starts with a path, only the path portion is set. All pseudo headers that
##  have been parsed/set are sent when the connection type is HTTP/2.
##
##  To set each slot explicitly, use `hyper_request_set_uri_parts`.
##

proc hyper_request_set_uri*(req: ptr hyper_request, uri: ptr uint8, uri_len: csize_t): hyper_code {.importc.}
##
##  Set the URI of the request with separate scheme, authority, and
##  path/query strings.
##
##  Each of `scheme`, `authority`, and `path_and_query` should either be
##  null, to skip providing a component, or point to a UTF-8 encoded
##  string. If any string pointer argument is non-null, its corresponding
##  `len` parameter must be set to the string's length.
##

proc hyper_request_set_uri_parts*(req: ptr hyper_request, scheme: ptr uint8,
                                 scheme_len: csize_t, authority: ptr uint8,
                                 authority_len: csize_t,
                                 path_and_query: ptr uint8,
                                 path_and_query_len: csize_t): hyper_code {.importc.}
##
##  Set the preferred HTTP version of the request.
##
##  The version value should be one of the `HYPER_HTTP_VERSION_` constants.
##
##  Note that this won't change the major HTTP version of the connection,
##  since that is determined at the handshake step.
##

proc hyper_request_set_version*(req: ptr hyper_request, version: cint): hyper_code {.importc.}
##
##  Gets a reference to the HTTP headers of this request
##
##  This is not an owned reference, so it should not be accessed after the
##  `hyper_request` has been consumed.
##

proc hyper_request_headers*(req: ptr hyper_request): ptr hyper_headers {.importc.}
##
##  Set the body of the request.
##
##  The default is an empty body.
##
##  This takes ownership of the `hyper_body *`, you must not use it or
##  free it after setting it on the request.
##

proc hyper_request_set_body*(req: ptr hyper_request, body: ptr hyper_body): hyper_code {.importc.}
##
##  Set an informational (1xx) response callback.
##
##  The callback is called each time hyper receives an informational (1xx)
##  response for this request.
##
##  The third argument is an opaque user data pointer, which is passed to
##  the callback each time.
##
##  The callback is passed the `void *` data pointer, and a
##  `hyper_response *` which can be inspected as any other response. The
##  body of the response will always be empty.
##
##  NOTE: The `hyper_response *` is just borrowed data, and will not
##  be valid after the callback finishes. You must copy any data you wish
##  to persist.
##

proc hyper_request_on_informational*(req: ptr hyper_request, callback: hyper_request_on_informational_callback,
                                    data: pointer): hyper_code {.importc.}
##
##  Free an HTTP response after using it.
##

proc hyper_response_free*(resp: ptr hyper_response) {.importc.}
##
##  Get the HTTP-Status code of this response.
##
##  It will always be within the range of 100-599.
##

proc hyper_response_status*(resp: ptr hyper_response): uint16 {.importc.}
##
##  Get a pointer to the reason-phrase of this response.
##
##  This buffer is not null-terminated.
##
##  This buffer is owned by the response, and should not be used after
##  the response has been freed.
##
##  Use `hyper_response_reason_phrase_len()` to get the length of this
##  buffer.
##

proc hyper_response_reason_phrase*(resp: ptr hyper_response): ptr uint8 {.importc.}
##
##  Get the length of the reason-phrase of this response.
##
##  Use `hyper_response_reason_phrase()` to get the buffer pointer.
##

proc hyper_response_reason_phrase_len*(resp: ptr hyper_response): csize_t {.importc.}
##
##  Get a reference to the full raw headers of this response.
##
##  You must have enabled `hyper_clientconn_options_headers_raw()`, or this
##  will return NULL.
##
##  The returned `hyper_buf *` is just a reference, owned by the response.
##  You need to make a copy if you wish to use it after freeing the
##  response.
##
##  The buffer is not null-terminated, see the `hyper_buf` functions for
##  getting the bytes and length.
##

proc hyper_response_headers_raw*(resp: ptr hyper_response): ptr hyper_buf {.importc.}
##
##  Get the HTTP version used by this response.
##
##  The returned value could be:
##
##  - `HYPER_HTTP_VERSION_1_0`
##  - `HYPER_HTTP_VERSION_1_1`
##  - `HYPER_HTTP_VERSION_2`
##  - `HYPER_HTTP_VERSION_NONE` if newer (or older).
##

proc hyper_response_version*(resp: ptr hyper_response): cint {.importc.}
##
##  Gets a reference to the HTTP headers of this response.
##
##  This is not an owned reference, so it should not be accessed after the
##  `hyper_response` has been freed.
##

proc hyper_response_headers*(resp: ptr hyper_response): ptr hyper_headers {.importc.}
##
##  Take ownership of the body of this response.
##
##  It is safe to free the response even after taking ownership of its body.
##

proc hyper_response_body*(resp: ptr hyper_response): ptr hyper_body {.importc.}
##
##  Iterates the headers passing each name and value pair to the callback.
##
##  The `userdata` pointer is also passed to the callback.
##
##  The callback should return `HYPER_ITER_CONTINUE` to keep iterating, or
##  `HYPER_ITER_BREAK` to stop.
##

proc hyper_headers_foreach*(headers: ptr hyper_headers,
                           `func`: hyper_headers_foreach_callback,
                           userdata: pointer) {.importc.}
##
##  Sets the header with the provided name to the provided value.
##
##  This overwrites any previous value set for the header.
##

proc hyper_headers_set*(headers: ptr hyper_headers, name: ptr uint8,
                       name_len: csize_t, value: ptr uint8, value_len: csize_t): hyper_code {.importc.}
##
##  Adds the provided value to the list of the provided name.
##
##  If there were already existing values for the name, this will append the
##  new value to the internal list.
##

proc hyper_headers_add*(headers: ptr hyper_headers, name: ptr uint8,
                       name_len: csize_t, value: ptr uint8, value_len: csize_t): hyper_code {.importc.}
##
##  Create a new IO type used to represent a transport.
##
##  The read and write functions of this transport should be set with
##  `hyper_io_set_read` and `hyper_io_set_write`.
##

proc hyper_io_new*(): ptr hyper_io {.importc.}
##
##  Free an unused `hyper_io *`.
##
##  This is typically only useful if you aren't going to pass ownership
##  of the IO handle to hyper, such as with `hyper_clientconn_handshake()`.
##

proc hyper_io_free*(io: ptr hyper_io) {.importc.}
##
##  Set the user data pointer for this IO to some value.
##
##  This value is passed as an argument to the read and write callbacks.
##

proc hyper_io_set_userdata*(io: ptr hyper_io, data: pointer) {.importc.}
##
##  Set the read function for this IO transport.
##
##  Data that is read from the transport should be put in the `buf` pointer,
##  up to `buf_len` bytes. The number of bytes read should be the return value.
##
##  It is undefined behavior to try to access the bytes in the `buf` pointer,
##  unless you have already written them yourself. It is also undefined behavior
##  to return that more bytes have been written than actually set on the `buf`.
##
##  If there is no data currently available, a waker should be claimed from
##  the `ctx` and registered with whatever polling mechanism is used to signal
##  when data is available later on. The return value should be
##  `HYPER_IO_PENDING`.
##
##  If there is an irrecoverable error reading data, then `HYPER_IO_ERROR`
##  should be the return value.
##

proc hyper_io_set_read*(io: ptr hyper_io, `func`: hyper_io_read_callback) {.importc.}
##
##  Set the write function for this IO transport.
##
##  Data from the `buf` pointer should be written to the transport, up to
##  `buf_len` bytes. The number of bytes written should be the return value.
##
##  If no data can currently be written, the `waker` should be cloned and
##  registered with whatever polling mechanism is used to signal when data
##  is available later on. The return value should be `HYPER_IO_PENDING`.
##
##  Yeet.
##
##  If there is an irrecoverable error reading data, then `HYPER_IO_ERROR`
##  should be the return value.
##

proc hyper_io_set_write*(io: ptr hyper_io, `func`: hyper_io_write_callback) {.importc.}
##
##  Creates a new task executor.
##

proc hyper_executor_new*(): ptr hyper_executor {.importc.}
##
##  Frees an executor and any incomplete tasks still part of it.
##

proc hyper_executor_free*(exec: ptr hyper_executor) {.importc.}
##
##  Push a task onto the executor.
##
##  The executor takes ownership of the task, it should not be accessed
##  again unless returned back to the user with `hyper_executor_poll`.
##

proc hyper_executor_push*(exec: ptr hyper_executor, task: ptr hyper_task): hyper_code {.importc.}
##
##  Polls the executor, trying to make progress on any tasks that have notified
##  that they are ready again.
##
##  If ready, returns a task from the executor that has completed.
##
##  If there are no ready tasks, this returns `NULL`.
##

proc hyper_executor_poll*(exec: ptr hyper_executor): ptr hyper_task {.importc.}
##
##  Free a task.
##

proc hyper_task_free*(task: ptr hyper_task) {.importc.}
##
##  Takes the output value of this task.
##
##  This must only be called once polling the task on an executor has finished
##  this task.
##
##  Use `hyper_task_type` to determine the type of the `void *` return value.
##

proc hyper_task_value*(task: ptr hyper_task): pointer {.importc.}
##
##  Query the return type of this task.
##

proc hyper_task_type*(task: ptr hyper_task): hyper_task_return_type {.importc.}
##
##  Set a user data pointer to be associated with this task.
##
##  This value will be passed to task callbacks, and can be checked later
##  with `hyper_task_userdata`.
##

proc hyper_task_set_userdata*(task: ptr hyper_task, userdata: pointer) {.importc.}
##
##  Retrieve the userdata that has been set via `hyper_task_set_userdata`.
##

proc hyper_task_userdata*(task: ptr hyper_task): pointer {.importc.}
##
##  Copies a waker out of the task context.
##

proc hyper_context_waker*(cx: ptr hyper_context): ptr hyper_waker {.importc.}
##
##  Free a waker that hasn't been woken.
##

proc hyper_waker_free*(waker: ptr hyper_waker) {.importc.}
##
##  Wake up the task associated with a waker.
##
##  NOTE: This consumes the waker. You should not use or free the waker afterwards.
##

proc hyper_waker_wake*(waker: ptr hyper_waker) {.importc.}
