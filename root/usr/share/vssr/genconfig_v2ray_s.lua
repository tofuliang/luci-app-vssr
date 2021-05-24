local ucursor = require'luci.model.uci'.cursor()
local name = 'vssr'
local json = require 'luci.jsonc'
local proto = 'socks'

local global = ucursor:get_all(name, ucursor:get_first(name, 'global'))
local socks5_proxy = ucursor:get_all(name, ucursor:get_first(name, 'socks5_proxy'))
local http_proxy = ucursor:get_all(name, ucursor:get_first(name, 'http_proxy'))
local dns_proxy = ucursor:get_all(name, ucursor:get_first(name, 'dns_proxy'))
local server = ucursor:get_all(name, ucursor:get_first(name, 'global', 'global_server'))

local http_switch = ucursor:get_first(name, 'socks5_proxy', 'enable_server')
local auth_typeh = ucursor:get_first(name, 'http_proxy', 'enable_auth')
local local_porth = ucursor:get_first(name, 'http_proxy', 'local_port')
local http_user = ucursor:get_first(name, 'http_proxy', 'http_user')
local http_pass = ucursor:get_first(name, 'http_proxy', 'http_pass')

function gen_inbound(sw, auth_type, local_port, user, pass, proto)
    local bound
    if sw == 0 then
        bound = nil
    else
        bound = {
            port = local_port,
            protocol = proto,
            settings = {
                auth = (auth_type == '1') and 'password' or 'noauth',
                accounts = (auth_type == '1') and {{user = (auth_type == '1') and user, pass = pass}} or nil
            }
        }
    end
    return bound
end

inbounds_table = {}

table.insert(inbounds_table, gen_inbound(socks_switch, auth_type, local_port, Socks_user, Socks_pass, 'socks'))
table.insert(inbounds_table, gen_inbound(http_switch, auth_typeh, local_porth, http_user, http_pass, 'http'))

local v2ray = {
	log = {
		--error = '/var/log/v2ray.log',
		loglevel = 'warning'
	},
	-- 传入连接
	inbounds = {},
	-- 传出连接
	outbound = {
		protocol = 'freedom'
	},
	-- 额外传出连接
	outboundDetour = {
		{
			protocol = 'blackhole',
			tag = 'blocked'
		}
	}
}

if global.combine_v2ray_client == '0' or server.type ~= 'v2ray' then
	if socks5_proxy.enable_server == '1' then
		local sock5 = {
			tag = proto,
			sniffing = {
				enabled = false,
				destOverride = {
					'http',
					'tls'
				}
			},
			port = tonumber(socks5_proxy.local_port),
			protocol = proto,
			settings = {
				userLevel = 0,
				udp = true,
				accounts = (socks5_proxy.enable_auth == '1') and  {
					{
						user = (socks5_proxy.enable_auth == '1') and socks5_proxy.Socks_user,
						pass = socks5_proxy.Socks_pass
					}
				} or nil,
				ip = '0.0.0.0',
				auth = (socks5_proxy.enable_auth == '1') and 'password' or 'noauth',
			}
		}

		table.insert(v2ray.inbounds,sock5)
	end
	if http_proxy.enable_server == '1' then
		local http = {
			tag = 'http',
			port = tonumber(http_proxy.local_port),
			protocol = 'http',
			settings = {
				accounts = {},
				timeout = 0,
				userLevel = 0,
				allowTransparent = false
			},
			sniffing = {
				enabled = false,
				destOverride = { 'http', 'tls' }
			}
		}
		if http_proxy.enable_auth == '1' and http_proxy.http_user ~= '' and http_proxy.http_pass ~= '' and http_proxy.http_user ~= nil and http_proxy.http_pass ~= nil then
			http.settings.auth = 'password'
			http.settings.accounts = {
				{
					user = http_proxy.http_user,
					pass = http_proxy.http_pass
				}
			}
		end
		table.insert(v2ray.inbounds,http)
	end
	if dns_proxy.enable_server == '1' then
		local dns = {
			tag = 'dns',
			protocol = 'dokodemo-door',
			port = tonumber(dns_proxy.local_port),
			settings = {
				address = dns_proxy.server_addr,
				port = tonumber(dns_proxy.server_port),
				network = 'udp',
				timeout = 0,
				followRedirect = false
			}
		}
		table.insert(v2ray.inbounds,dns)
	end
end

print(json.stringify(v2ray,1))
