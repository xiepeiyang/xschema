local schema = require 'schema'

-- step 1: define schema
Req = {
    page = schema.Number({default=1, min=1}),
    pagesize = schema.Number({default=10, min=1, max=100}),
    filter = {
        name = schema.String({nonil=true}),
        category = schema.String(),
        age_between = {
            tbeg = schema.Number({min=0}),
            tend = schema.Number({min=1, max=100})
        }
    }
}

-- case 1
local req_var = {page=0}
local req, errmsg = schema.Parse(Req, req_var)
print('\ncase 1: ' .. errmsg)

-- case 2
req_var = {page=2, filter={category='cat'}}
req, errmsg = schema.Parse(Req, req_var)
print('case 2: ' .. errmsg)

-- case 3
req_var = {page=2, filter={name='Jack', category='cat', age_between={tbeg=3}}}
req, errmsg = schema.Parse(Req, req_var)
print('\ncase 3')
print('page: ' .. req.page)
print('pagesize: ' .. req.pagesize)
print('filter.name: ' .. req.filter.name)
print('filter.category: ' .. req.filter.category)
print('filter.age_between.tbeg: ' .. req.filter.age_between.tbeg)
