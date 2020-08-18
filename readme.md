## parse openresty request data with simple rules.

### Example 1

```lua
local xschema = require "xschema"

local Req = {
    page       = xschema.Number({default = 1, min = 1}),
    pagesize   = xschema.Number({default = 10, min = 5, max = 50}),
    keyword    = xschema.String({nonil = true})
}

local req, err = xschema.HttpParse(Req, ngx.req)
print(req.keyword)
```

### Example 2

```lua

local Req = {
    userid    = xschema.Number({nonil = true}),
    imgs      = xschema.Array({
                    url  = xschema.String({nonil = true}),
                    size = xschema.Number({nonil = true, min = 1})
                })
}

local req, err = xschema.HttpParse(Req, ngx.req)
print(req.userid)
```

feel free to add more rules in source file