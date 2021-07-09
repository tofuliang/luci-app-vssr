local m, s, o
local NXFS = require 'nixio.fs'
local router_table = {
    a1 = {
        name = 'youtube',
        des = 'Youtube Domain'
    },
    a2 = {
        name = 'tw_video',
        des = 'Tw Video Domain'
    },
    a3 = {
        name = 'netflix',
        des = 'Netflix Domain'
    },
    a4 = {
        name = 'disney',
        des = 'Disney+ Domain'
    },
    a5 = {
        name = 'prime',
        des = 'Prime Video Domain'
    },
    a6 = {
        name = 'tvb',
        des = 'TVB Domain'
    },
    a7 = {
        name = 'custom',
        des = 'Custom Domain'
    },
    a8 = {
        name = 'custom2',
        des = 'Custom Domain'
    },
    a9 = {
        name = 'custom3',
        des = 'Custom Domain'
    }
}

function pairsByKeys(t)
    local a = {}
    for n in pairs(t) do a[#a + 1] = n end
    table.sort(a)
    local i = 0
    return function ()
        i = i + 1
        return a[i], t[a[i]]
    end
end

m = Map('vssr', translate('Router domain config'))
s = m:section(TypedSection, 'access_control')
s.anonymous = true

local cusN=1
for _, v in pairsByKeys(router_table) do
    if string.sub(v.name,1,string.len("custom"))=="custom" then
        s:tab(v.name, translate(v.des)..cusN)
        cusN = cusN+1
    else
        s:tab(v.name, translate(v.des))
    end
    local conf = '/etc/vssr/'.. v.name ..'_domain.list'
    o = s:taboption(v.name, TextValue, v.name ..'conf')
    o.rows = 13
    o.description = translate('↑ Put your domain list here')
    o.wrap = 'off'
    o.rmempty = true
    o.cfgvalue = function(self, section)
        return NXFS.readfile(conf) or ' '
    end
    o.write = function(self, section, value)
        NXFS.writefile(conf, value:gsub('\r\n', '\n'))
    end
    o.remove = function(self, section, value)
        NXFS.writefile(conf, '')
    end

    local conf1 = '/etc/vssr/'.. v.name ..'_ip.list'
    o = s:taboption(v.name, TextValue, v.name ..'conf1')
    o.rows = 13
    o.wrap = 'off'
    o.description = translate('↑ Put your IP list here')
    o.rmempty = true
    o.cfgvalue = function(self, section)
        return NXFS.readfile(conf1) or ' '
    end
    o.write = function(self, section, value)
        NXFS.writefile(conf1, value:gsub('\r\n', '\n'))
    end
    o.remove = function(self, section, value)
        NXFS.writefile(conf1, '')
    end
end

return m
