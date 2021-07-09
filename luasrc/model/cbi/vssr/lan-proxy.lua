--[[
Author: your name
Date: 2019-11-11 09:33:07
LastEditTime: 2021-01-14 18:50:06
LastEditors: Please set LastEditors
Description: In User Settings Edit
FilePath: \luci-app-vssr\luasrc\model\cbi\vssr\socks5.lua
--]]
local vssr = 'vssr'
local uci = luci.model.uci.cursor()

local server_table = {}
uci:foreach(
    'vssr',
    'servers',
    function(s)
        if s.type ~= nil then
            s['name'] = s['.name']
            local alias = (s.alias ~= nil) and s.alias or "未命名节点"
            s['gname'] = '[%s]:%s' % {string.upper(s.type), alias}
            table.insert(server_table, s)
        end
    end
)
function my_sort(a,b)
    if(a.alias ~= nil and b.alias ~= nil) then
        return  a.alias < b.alias
    end
end
table.sort(server_table, my_sort)

m = Map(vssr)

-- [[ SOCKS5 Proxy ]]--
if nixio.fs.access('/usr/bin/xray') then
    s = m:section(TypedSection, 'socks5_proxy', translate('Xray SOCKS5 Proxy'))
    s.anonymous = true

    o = s:option(Flag, 'enable_server', translate('Enable Servers'))
    o.rmempty = false

    o = s:option(Flag, 'enable_auth', translate('Enable Auth'))
    o.rmempty = false

    o = s:option(Value, 'socks_user', translate('Socks user'))
    o.default = ''
    o.rmempty = true
    o:depends('enable_auth', '1')

    o = s:option(Value, 'socks_pass', translate('Socks pass'))
    o.default = ''
    o.password = true
    o.rmempty = true
    o:depends('enable_auth', '1')

    o = s:option(Value, 'local_port', translate('Local Port'))
    o.datatype = 'port'
    o.default = 1080
    o.rmempty = false

    o = s:option(ListValue, 'proxy_server', translate('Proxy Server'))
    o:value('nil', translate('Same as Main Server'))
    for _, key in pairs(server_table) do
        o:value(key.name, key.gname)
    end
    o.default = 'nil'
    o.rmempty = false

end

-- [[ Http Proxy ]]--
if nixio.fs.access('/usr/bin/xray') then
    s = m:section(TypedSection, 'http_proxy', translate('Xray HTTP Proxy'))
    s.anonymous = true

    o = s:option(Flag, 'enable_server', translate('Enable Servers'))
    o.rmempty = false

    o = s:option(Flag, 'enable_auth', translate('Enable Auth'))
    o.rmempty = false

    o = s:option(Value, 'http_user', translate('HTTP User'))
    o.default=''
    o.rmempty = true
    o:depends('enable_auth', '1')

    o = s:option(Value, 'http_pass', translate('HTTP Pass'))
    o.default=''
    o.password = true
    o.rmempty = true
    o:depends('enable_auth', '1')

    o = s:option(Value, 'local_port', translate('Local Port'))
    o.datatype = 'port'
    o.default = 8080
    o.rmempty = false

    o = s:option(ListValue, 'proxy_server', translate('Proxy Server'))
    o:value('nil', translate('Same as Main Server'))
    for _, key in pairs(server_table) do
        o:value(key.name, key.gname)
    end
    o.default = 'nil'
    o.rmempty = false

end

-- [[ DNS Proxy ]]--
if nixio.fs.access('/usr/bin/xray') then
    s = m:section(TypedSection, 'dns_proxy', translate('Xray DNS Proxy'))
    s.anonymous = true

    o = s:option(Flag, 'enable_server', translate('Enable Servers'))
    o.rmempty = false

    o = s:option(Value, 'server_addr', translate('DNS Server'))
    o.default=''
    o.rmempty = true

    o = s:option(Value, 'server_port', translate('DNS Port'))
    o.default=''
    o.rmempty = true

    o = s:option(Value, 'local_port', translate('Local Port'))
    o.datatype = 'port'
    o.default = 7913
    o.rmempty = false

    o = s:option(ListValue, 'proxy_server', translate('Proxy Server'))
    o:value('nil', translate('Same as Main Server'))
    for _, key in pairs(server_table) do
        o:value(key.name, key.gname)
    end
    o.default = 'nil'
    o.rmempty = false

end

return m
