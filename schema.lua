local cjson = require 'cjson'

local _OK = ''

local _Schema = {}

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
    for field, func in pairs(define) do
        if type(func) == 'table' then
            -- process table, recursive...
            local value, errmsg = _Schema.Parse(func, obj[field])
            if errmsg ~= _OK then
                return nil, errmsg
            end
            r[field] = value
        else
            local value = nil
            if obj ~= nil then
                value = obj[field]
            end
            local default, errmsg = func(value, field)
            if errmsg ~= _OK then
                return nil, errmsg
            elseif default ~= nil then
                r[field] = default
            else
                r[field] = value
            end
        end
    end
    return r, _OK
end

function _Schema.Validate(define, obj)
    local r, errmsg = _Schema.Parse(define, obj)
    return errmsg
end

-- check default and nonil
function _Schema.__common(opt, obj, field)
    local ISNIL = true
    if obj == nil and opt.nonil == true then
        return nil, field .. ' is nil', false
    end
    if obj == nil and opt.default ~= nil then
        return opt.default, _OK, false
    end
    if obj == nil then
        -- nil is allow
        return nil, _OK, ISNIL
    end
    return nil, _OK, false
end

function _Schema.Boolen(opt)
    local function _check(obj, field)
        local default, errmsg, isnil = _Schema.__common(opt, obj, field)
        if default ~= nil or errmsg ~= _OK or isnil then
            return default, errmsg
        end

        if type(obj) ~= 'boolen' then
            return  nil, _errmsg(field, obj, 'is not boolen')
        end
        return nil, _OK
    end
    return _check
end

function _Schema.String(opt)
    local function _check(obj, field)
        local default, errmsg, isnil = _Schema.__common(opt, obj, field)
        if default ~= nil or errmsg ~= _OK or isnil then
            return default, errmsg
        end

        if type(obj) ~= 'string' then
            return nil, _errmsg(field, obj, 'is not string')
        end
        return nil, _OK
    end
    return _check
end

function _Schema.Number(opt)
    local function _check(obj, field)
        local default, errmsg, isnil = _Schema.__common(opt, obj, field)
        if default ~= nil or errmsg ~= _OK or isnil then
            return default, errmsg
        end

        if type(obj) ~= 'number' then
            return nil, _errmsg(field, obj, 'is not number')
        end 
        if opt.min ~= nil and opt.min > obj then
            return nil, _errmsg(field, obj, 'is smaller than', opt.min)
        end
        if opt.max ~= nil and opt.max < obj then
            return nil, _errmsg(field, obj, 'is larger than', opt.max)
        end
        return nil, _OK
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
    return field .. ': ' .. obj .. ' ' .. msg .. ' ' .. arg
end

return _Schema
