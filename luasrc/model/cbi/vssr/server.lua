-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.
local m, sec, o
local vssr = 'vssr'

m = Map(vssr, translate('vssr Server'))

obfs = {
    'plain',
    'http_simple',
    'http_post',
    'random_head',
    'tls1.2_ticket_auth',
    'tls1.2_ticket_fastauth'
}

-- [[ Global Setting ]]--
sec = m:section(TypedSection, 'server_global', translate('Global Setting'))
sec.anonymous = true

o = sec:option(Flag, 'enable_server', translate('Enable Server'))
o.rmempty = false

-- [[ Server Setting ]]--
sec = m:section(TypedSection, 'server_config', translate('Server Setting'))
sec.anonymous = true
sec.addremove = true
sec.template = 'cbi/tblsection'
sec.extedit = luci.dispatcher.build_url('admin/services/vssr/server/%s')
function sec.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(sec.extedit % sid)
        return
    end
end

o = sec:option(Flag, 'enable', translate('Enable'))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or translate('0')
end
o.rmempty = false

o = sec:option(DummyValue, 'server_port', translate('Server Port'))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or '?'
end

o = sec:option(DummyValue, 'encrypt_method', translate('Encrypt Method'))
function o.cfgvalue(...)
    local v = Value.cfgvalue(...)
    return v and v:upper() or '?'
end

o = sec:option(DummyValue, 'protocol', translate('Protocol'))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or '?'
end

o = sec:option(DummyValue, 'obfs', translate('Obfs'))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or '?'
end

return m
