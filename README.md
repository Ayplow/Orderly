# Orderly

## Documentation
Orderly is a [Promises/A+](https://promisesaplus.com/) library based on [promise.lua](https://github.com/Billiam/promise.lua), with support for the [async/await model](https://tc39.github.io/ecmascript-asyncawait/)

Promises represent the result of an operation which will complete in the future. They can be passed around, chained onto,
and can help to flatten out deeply nested callback code, and simplify error handling to some degree.

There are many, and much better, introductions to promise patterns.
 * https://www.promisejs.org/
 * https://www.promisejs.org/patterns/

Feel free to send a pull request with improved documentation, and/or references.

## Installation

Add the orderly.lua file to your application and require it -

```lua
local Promise = require("orderly")
local async, await = Promise.async, Promise.await
```

Promises are resolved asynchronously, and require either a callback akin to javascript's setTimeout, or a periodic call to
`Promise.update()`. This can be accomplished in a couple of ways.

When using an event loop, like lua-ev, you can set `Promise.register` to a function which will schedule a callback for a later time.

```lua
Promise.register = function(callback)
  my_ev_loop.create_timer(0, callback)
end
```

## Examples
```lua
local Promise = require('promise')

local promise = Promise.new()

promise:next(function(result)
  print('promise resolved', result)
end, function(reason)
  print('promise was rejected', reason)
end)
```


Promises may be chained repeatedly.

```lua
local promise = Promise.new()

promise:next(function(result)
  print('result1')
end)

local promise2 = promise:next(function(result)
  print('result2')
end)

promise2:next(function(result)
  print('I only run after promise2 resolves')
end)
```

```lua
local memoizedPromise
local fetchJson = function()
  if not memoizedPromise then
    memoizedPromise = Promise.new()
    
    fetchJsonEventually(function(json)
      promise:resolve(json)
    end)
  end
  
  return memoizedPromise
end

fetchJson():next(function(json)
  return JSON.parse(json)
end):next(function(parsed_json)
  return parsed_json.specific_value
end):next(function(specific_value)
  print('got specific value')
end):catch(function(reason)
  print('an error occurred while fetching the value', reason)
end)
```


If an error occurs in an onFulfilled callback, that promise will be rejected with the value of the error.

```lua
local promise = Promise.new()
promise:next(function()
  error('something bad happened!')
):catch(function(reason)
  print(reason)
end)
```

These errors may be caught, and handled in the callback chain:
```lua
local promise = Promise.new()

promise:next(function()
  return fetchValueWhichCausesAnError()
):catch(function(reason)
  print(reason)
  
  return myDefaultValue
end):next(function(result)
  print('"result" is either the value returned from fetchValue call, or the myDefaultValue if that threw an error')
end)
```

## Usage

### Promise.new()
Creates a new promise which may later be resolved or rejected.

```lua
local promise = Promise.new()

promise:next(callback):next(callback):catch(error_handler)
```

### promise:next(onFulfilled, onRejected)
Returns a _new_ promise, adding it to the current promise's chain.

`onFulfilled` will be called when the promise resolves. `onRejected` will be called when the promise is rejected.
Both arguments are optional.

```lua
local promise = Promise.new()
promise:next(function(result)
  print('this callback was successful and returned', result)
end, function(reason)
  print('this promise was rejected because', reason)
end)
```

### promise:catch(onRejected)

Alias for `promise.next(nil, onRejected)`

### promise:resolve(value)
Resolves the promise with `value`

### promise:reject(reason)
Rejects the promise with `reason`

### Promise.all()

Creates a promise which resolves after _all_ of its promises resolve, or rejects when _any_ of its promises fail.

```lua
local promise1 = Promise.new()
local promise2 = Promise.new()
local promise3 = Promise.new()

Promise.all(promise1, promise2, promise3):next(function(results)
  local result1, result2, result3 = unpack(results)
  print('All promises have resolved')
end, function(reason)  
  print('A promise was rejected because: ', reason)
end)

-- some time later
promise1:resolve(1)
promise2:resolve(2)
promise3:resolve(3)
```

### Promise.race()

Creates a promise which resolves as soon as _any_ of its promises resolve, or rejects when _all_ provided promises
fail.

```lua
local promise1 = Promise.new()
local promise2 = Promise.new()

Promise.race(promise1, promise2):next(function(value)
  print('The first promise to resolve returned ' .. value)
end, function(results)
  local result1, result2 = unpack(results)
  
  print('All promises were rejected')
end)

-- some time later

promise2:resolve('I resolved first!')
```

## Differences from the Promises/A+ Spec

* [1.2](https://promisesaplus.com/#point-7) `then` is a reserved word in Lua. `next` is used instead in this library.
* [1.3](https://promisesaplus.com/#point-8) Valid value types
  * Promises cannot be resolved with null (`nil`). Lua does not distinguish between
  
    ```lua
    function()
        return nil
    end
    ```
    
    and  
    
    ```lua
    function()
        return
    end
    ```
    
  * Lua does not have an `undefined` type.
* [2.2.5](https://promisesaplus.com/#point-35) Lua method calls do not have a `this` equivalent. The `self` syntactic sugar for `self` is determined by method arguments.
* [2.3.1](https://promisesaplus.com/#point-48) Lua does not have an error type. Specifications calling for `TypeError` will receive a string message beginning with `TypeError:`
* [2.3.3.3](https://promisesaplus.com/#point-56) Lua method calls do not have a `this` equivalent. `next` will be called with the first argument of `x` instead.

## Running the test suite

```sh
# Install luarocks
sudo apt-get install luarocks
# Install luasec (required to install specific version of busted)
sudo luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu/
# Install libev, if not already installed
sudo apt-get install libev-dev
# Install lua-ev
luarocks install lua-ev scm --server=http://luarocks.org/repositories/rocks-scm/
# Install busted
sudo luarocks install busted 1.11.1-2
# Run busted
busted spec
```

### Related projects:

If you want to use async/await with another promise library, the keywords can be required on their own -

```lua
Promise = require "MyPromiseLibrary"
async, await = require "orderly/keywords" (Promise.new, function(promise, handler) promise:Then(handler) end, function(promise, handler) promise:Catch(handler) end)
```

* [AndThen](https://github.com/ppissanetzky/AndThen)
* [lua_promise](https://github.com/friesencr/lua_promise)
* [lua-promise](https://github.com/dmccuskey/lua-promise)
* [next.lua](https://github.com/pmachowski/next-lua)
* [promise](https://github.com/Olivine-Labs/promise)
* [promise.lua](https://github.com/Billiam/promise.lua)

Missing one? Send a pull request!
