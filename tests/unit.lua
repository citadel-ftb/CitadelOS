lu = require('vendor/luaunit/luaunit')

require('tests/unit/chunk_test')

os.exit(lu.LuaUnit.run())