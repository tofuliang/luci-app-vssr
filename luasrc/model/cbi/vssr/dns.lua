local vssr = 'vssr'

m = Map(vssr)

-- [[ DNS Proxy ]]--
if nixio.fs.access('/usr/bin/v2ray/v2ray') or nixio.fs.access('/usr/bin/v2ray') or nixio.fs.access('/usr/bin/xray') or nixio.fs.access('/usr/bin/xray/xray') then
    s = m:section(TypedSection, 'dns_proxy', translate('V2ray DNS Proxy'))
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
end

return m
