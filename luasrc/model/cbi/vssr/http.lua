local vssr = 'vssr'

m = Map(vssr)

-- [[ HTTP Proxy ]]--
if nixio.fs.access('/usr/bin/v2ray/v2ray') or nixio.fs.access('/usr/bin/v2ray') or nixio.fs.access('/usr/bin/xray') or nixio.fs.access('/usr/bin/xray/xray') then
    s = m:section(TypedSection, 'http_proxy', translate('V2ray HTTP Proxy'))
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
end

return m
