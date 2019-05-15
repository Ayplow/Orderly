_ENV.require = nil
local require = loadfile "D:\\Programming\\lua-vfs\\knowledge_base\\lua\\relative_require.lua" () (...)


-- local require = require "relative_require" (...)

local restore = package.path
package.path = "./?.lua"

local Promise = require "Promise"
Promise.async, Promise.await = require "keywords" (
    Promise.new,
    function(promise, handler) promise:next(handler) end,
    function(promise, handler) promise:catch(handler) end)

package.path = restore

return Promise