local cjson = require 'cjson'
local _Schema = {
    MaxInt32 = 2147483647,
    MaxLuaInt = 4503599627370496
}
_Schema.OK = ''

function _Schema.HttpParse(define, req)
    -- read data from get or post
    local args
    if req.get_method() == 'GET' then
        args = req.get_uri_args()
    else
        -- json only
        req.read_body()
        args = req.get_body_data()
        local status, err = pcall(function ()
            args = cjson.decode(args)
        end)
        if status == false then
            return nil, 'POST data error: not json'
        end
    end
    -- parse
    return _Schema.Parse(define, args)
end

function _Schema.Parse(define, obj)
    local r = {}
    local retmsg = _Schema.OK
    for field, func in pairs(define) do
        local errmsg = _Schema.OK
        local value = nil
        if obj ~= nil then
            value = obj[field]
        end
        if type(func) == 'table' then
            -- process table, recursive...
            value, errmsg = _Schema.Parse(func, value)
        else
            value, errmsg = func(value, field)
        end
        if errmsg ~= _Schema.OK then
            retmsg = errmsg
        end
        r[field] = value
    end
    return r, retmsg
end

function _Schema.Validate(define, obj)
    local r, errmsg = _Schema.Parse(define, obj)
    return errmsg
end

function _Schema.__common(opt, obj, field)
    -- check nonil
    if obj == nil and opt.nonil == true then
        return nil, field .. ' is nil'
    end
    -- check default
    if obj == nil and opt.default ~= nil then
        return opt.default, _Schema.OK
    end
    return nil, _Schema.OK
end

function _Schema.Boolen(opt)
    local function _check(obj, field)
        local default, errmsg = _Schema.__common(opt, obj, field)
        if default ~= nil or errmsg ~= _Schema.OK then
            return default, errmsg
        end
        if obj == nil then
            return false, _Schema.OK
        end
        if obj ~= 'true' and obj ~= 'True' and tonumber(obj) ~= 1 then
            return false, _Schema.OK
        end
        return true, _Schema.OK
    end
    return _check
end

function _Schema.String(opt)
    local function _check(obj, field)
        local default, errmsg = _Schema.__common(opt, obj, field)
        if obj == "" then
            if opt.default ~= nil then
                return opt.default, _Schema.OK
            end
            return '', _Schema.OK
        end
        if default ~= nil or errmsg ~= _Schema.OK then
            return default, errmsg
        end
        if obj == nil then
            return '', _Schema.OK
        end
        if type(obj) ~= 'string' then
            if obj ~= nil and opt.allowerr == true then
                return tostring(obj), _Schema.OK
            end
            return '', _errmsg(field, obj, 'is not string')
        end
        if opt.isnumber == true and tonumber(obj) == nil then
            return '', _errmsg(field, obj, "can't cast to number")
        end
        if opt.must_in ~= nil and type(opt.must_in) == 'table' and _must_in(obj, opt.must_in) == false then
            return 0, _errmsg(field, obj, 'value error')
        end
        if opt.htmlescape == true then
            obj = _html_escape(obj)
        end
        return obj, _Schema.OK
    end
    return _check
end

-- TODO float and integer

function _Schema.Number(opt)
    local function _check(obj, field)
        local default, errmsg = _Schema.__common(opt, obj, field)
        if obj == "" then
            if opt.default ~= nil then
                return opt.default, _Schema.OK
            end
            return 0, _Schema.OK
        end
        if default ~= nil or errmsg ~= _Schema.OK then
            return default, errmsg
        end
        obj = tonumber(obj)
        if type(obj) ~= 'number' then
            if opt.default ~= nil and opt.allowerr == true then
                return opt.default, _Schema.OK
            end
            return 0, _errmsg(field, obj, 'is not number')
        end
        if opt.must_in ~= nil and type(opt.must_in) == 'table' and _must_in(obj, opt.must_in) == false then
            return 0, _errmsg(field, obj, 'value error')
        end
        if opt.min ~= nil and opt.min > obj then
            return obj, _errmsg(field, obj, 'is smaller than', opt.min)
        end
        if opt.max ~= nil and opt.max < obj then
            return obj, _errmsg(field, obj, 'is larger than', opt.max)
        end
        return obj, _Schema.OK
    end
    return _check
end

function _Schema.Array(opt)
    local function _check(obj, field)
        if obj == nil then
            return nil, _Schema.OK
        end
        if type(obj) ~= 'table' then
            return nil, _errmsg(field, obj, 'not array')
        end
        local array = {}
        for i, item in ipairs(obj) do
            if type(i) == 'number' then
                if opt == "number" or opt == "string" then
                    if type(item) ~= opt then
                        return nil, _errmsg(field, item, 'is not ' .. opt)
                    end
                    table.insert(array, item)
                end
                if type(opt) == 'table' then
                    local value, errmsg = _Schema.Parse(opt, item)
                    if errmsg ~= _Schema.OK then
                        return nil, errmsg
                    end
                    table.insert(array, value)
                end
            end
        end
        return array, _Schema.OK
    end
    return _check
end

function _errmsg(field, obj, msg, arg)
    if arg == nil then
        arg = ''
    end
    if obj == nil then
        obj = 'nil'
    end
    if type(obj) ~= 'string' then
        obj = tostring(obj)
    end
    obj = _html_escape(obj)
    return field .. ': ' .. obj .. ' ' .. msg .. ' ' .. arg
end

function _html_escape(s)
    return (string.gsub(s, "[}{\">/<'&]", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;",
        ["/"] = "&#47;"
    }))
end

function _must_in(obj, array)
    for _, v in pairs(array) do
        if obj == v then
            return true
        end
    end
    return false
end

return _Schema
