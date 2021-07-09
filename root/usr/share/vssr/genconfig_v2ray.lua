local ucursor = require 'luci.model.uci'.cursor()
local name = 'vssr'
local json = require 'luci.jsonc'
local nixio = require 'nixio'
local server_section = arg[1]
local proto = arg[2]
local local_port = arg[3]
local outbounds_table = {}
local rules_table = {}

function read_conf(file)
    if not nixio.fs.access(file) then
        return nil
    end
    local rfile = io.open(file, "r")
    local ltable = {}
    for line in rfile:lines() do
        local re = string.gsub(line, "\r", "")
        table.insert(ltable,re)
    end
    local rtable = next(ltable) ~= nil and ltable or nil
    return rtable
end


local v2ray_flow = ucursor:get_first(name, 'global', 'v2ray_flow', '0')

local custom_domain = read_conf("/etc/vssr/custom_domain.list")
local custom_ip = read_conf("/etc/vssr/custom_ip.list")

local custom_domain2 = read_conf("/etc/vssr/custom2_domain.list")
local custom_ip2 = read_conf("/etc/vssr/custom2_ip.list")

local custom_domain3 = read_conf("/etc/vssr/custom3_domain.list")
local custom_ip3 = read_conf("/etc/vssr/custom3_ip.list")

local youtube_domain = read_conf("/etc/vssr/youtube_domain.list")
local youtube_ip = read_conf("/etc/vssr/youtube_ip.list")

local tw_video_domain = read_conf("/etc/vssr/tw_video_domain.list")
local tw_video_ip = read_conf("/etc/vssr/tw_video_ip.list")

local netflix_domain = read_conf("/etc/vssr/netflix_domain.list")
local netflix_ip = read_conf("/etc/vssr/netflix_ip.list")

local disney_domain = read_conf("/etc/vssr/disney_domain.list")
local disney_ip = read_conf("/etc/vssr/disney_ip.list")

local prime_domain = read_conf("/etc/vssr/prime_domain.list")
local prime_ip = read_conf("/etc/vssr/prime_ip.list")

local tvb_domain = read_conf("/etc/vssr/tvb_domain.list")
local tvb_ip = read_conf("/etc/vssr/tvb_ip.list")


local flow_table = {
    yotube = {
        name = 'youtube',
        port = 2081,
        rules = {
            type = 'field',
            domain = youtube_domain,
            ip = youtube_ip,
            outboundTag = 'youtube'
        }
    },
    tw_video = {
        name = 'tw_video',
        port = 2082,
        rules = {
            type = 'field',
            domain = tw_video_domain,
            ip = tw_video_ip,
            outboundTag = 'tw_video'
        }
    },
    netflix = {
        name = 'netflix',
        port = 2083,
        rules = {
            type = 'field',
            domain = netflix_domain,
            ip = netflix_ip,
            outboundTag = 'netflix'
        }
    },
    disney = {
        name = 'disney',
        port = 2084,
        rules = {
            type = 'field',
            domain = disney_domain,
            ip = disney_ip,
            outboundTag = 'disney'
        }
    },
    prime = {
        name = 'prime',
        port = 2085,
        rules = {
            type = 'field',
            domain = prime_domain,
            ip = prime_ip,
            outboundTag = 'prime'
        }
    },
    tvb = {
        name = 'tvb',
        port = 2086,
        rules = {
            type = 'field',
            domain = tvb_domain,
            ip = tvb_ip,
            outboundTag = 'tvb'
        }
    },
    custom = {
        name = 'custom',
        port = 2087,
        rules = {
            type = 'field',
            domain = custom_domain,
            ip = custom_ip,
            outboundTag = 'custom'
        }
    },
    custom2 = {
        name = 'custom2',
        port = 2088,
        rules = {
            type = 'field',
            domain = custom_domain2,
            ip = custom_ip2,
            outboundTag = 'custom2'
        }
    },
    custom3 = {
        name = 'custom3',
        port = 2089,
        rules = {
            type = 'field',
            domain = custom_domain3,
            ip = custom_ip3,
            outboundTag = 'custom3'
        }
    }
}

local bt_rules = {
    type = 'field',
    outboundTag = 'bt',
    protocol = {
        'bittorrent'
    }
}
local bt_rules1 = {
    type = 'field',
    outboundTag = 'bt',
    domain = {
        'torrent',
        'peer_id=',
        'info_hash',
        'get_peers',
        'find_node',
        'BitTorrent',
        'announce_peer',
        'announce.php?passkey='
    }
}

local global = ucursor:get_all(name, ucursor:get_first(name, "global"))
local socks5_proxy = ucursor:get_all(name, ucursor:get_first(name, "socks5_proxy"))
local http_proxy = ucursor:get_all(name, ucursor:get_first(name, "http_proxy"))
local dns_proxy = ucursor:get_all(name, ucursor:get_first(name, "dns_proxy"))

function gen_outbound(server_node, tags, local_ports)
    local bound = {}
    if server_node == nil or server_node == 'nil' then
        bound = nil
    else
        local server = ucursor:get_all(name, server_node)
        local node_type = server.type == 'vless' and 'vless' or 'vmess'

        if server.type == 'socks5' then
            bound = {
                tag = tags,
                protocol = 'socks',
                settings = {
                    servers = {
                        {address = server.server, port = tonumber(server.server_port)}
                    }
                }
            }
        elseif server.type ~= 'v2ray' and server.type ~= 'vless' then
            bound = {
                tag = tags,
                protocol = 'socks',
                settings = {
                    servers = {
                        {address = '127.0.0.1', port = tonumber(local_ports)}
                    }
                }
            }
        else
            bound = {
                tag = tags,
                protocol = node_type,
                settings = {
                    vnext = {
                        {
                            address = server.server,
                            port = tonumber(server.server_port),
                            users = {
                                {
                                    id = server.vmess_id,
                                    alterId = server.type == "v2ray" and tonumber(server.alter_id) or nil,
                                    security =  server.type == "v2ray" and server.security or nil,
                                    flow = (server.xtls == '1') and (server.vless_flow and server.vless_flow or "xtls-rprx-origin") or nil,
                                    encryption = server.type == "vless" and server.vless_encryption or nil
                                }
                            }
                        }
                    }
                },
                -- 底层传输配置
                streamSettings = {
                    network = server.transport,
                    security = (server.tls == '1') and ((server.xtls == '1') and 'xtls' or 'tls') or 'none',
                    tlsSettings = (server.tls == '1' and server.xtls ~= '1') and {allowInsecure = (server.insecure ~= '0') and true or false,serverName=server.tls_host,} or nil,
                    xtlsSettings = (server.xtls == '1') and {allowInsecure = (server.insecure ~= '0') and true or false,serverName=server.tls_host,} or nil,
                    kcpSettings = (server.transport == 'kcp') and
                        {
                            mtu = tonumber(server.mtu),
                            tti = tonumber(server.tti),
                            uplinkCapacity = tonumber(server.uplink_capacity),
                            downlinkCapacity = tonumber(server.downlink_capacity),
                            congestion = (server.congestion == '1') and true or false,
                            readBufferSize = tonumber(server.read_buffer_size),
                            writeBufferSize = tonumber(server.write_buffer_size),
                            header = {type = server.kcp_guise}
                        } or
                        nil,
                    wsSettings = (server.transport == 'ws') and (server.ws_path ~= nil or server.ws_host ~= nil) and
                        {
                            path = server.ws_path,
                            headers = (server.ws_host ~= nil) and {Host = server.ws_host} or nil
                        } or
                        nil,
                    httpSettings = (server.transport == 'h2') and {path = server.h2_path, host = server.h2_host} or nil,
                    quicSettings = (server.transport == 'quic') and
                        {
                            security = server.quic_security,
                            key = server.quic_key,
                            header = {type = server.quic_guise}
                        } or
                        nil
                },
                mux = {
                    enabled = (server.mux == '1') and true or false,
                    concurrency = tonumber(server.concurrency)
                }
            }
        end
    end
    return bound
end

function gen_bt_outbounds()
    local bound = {
        tag = 'bt',
        protocol = 'freedom',
        settings = {
            a = 1
        }
    }
    return bound
end

if v2ray_flow == '1' then
    
    table.insert(outbounds_table, gen_outbound(server_section, 'global', 2080))
    for _, v in pairs(flow_table) do
        if(v.rules.domain ~= nil or v.rules.ip ~= nil) then
            local server = ucursor:get_first(name, 'global', v.name .. '_server')
            table.insert(outbounds_table, gen_outbound(server, v.name, v.port))

            if(v.rules.domain ~= nil) then
                domain_rules = {
                    type = 'field',
                    domain = v.rules.domain,
                    outboundTag = v.rules.outboundTag
                }
                table.insert(rules_table, (server ~= nil and server ~= 'nil' ) and domain_rules or nil)
            end
            
            if(v.rules.ip ~= nil) then
                ip_rules = {
                    type = 'field',
                    ip = v.rules.ip,
                    outboundTag = v.rules.outboundTag
                }
                table.insert(rules_table, (server ~= nil and server ~= 'nil' ) and ip_rules or nil)
            end
        end
    end
else
    table.insert(outbounds_table, gen_outbound(server_section, 'main', local_port))
end

if socks5_proxy.enable_server == '1' then
    if socks5_proxy.proxy_server ~= nil and socks5_proxy.proxy_server ~= 'nil' then
        table.insert(outbounds_table, gen_outbound(socks5_proxy.proxy_server, 'socks5', 2090))
    end
    table.insert(rules_table, (socks5_proxy.proxy_server ~= nil and socks5_proxy.proxy_server ~= 'nil') and {type = 'field',inboundTag = {'socks5'},outboundTag = 'socks5'} or nil)
end

if http_proxy.enable_server == '1' then
    if http_proxy.proxy_server ~= nil and http_proxy.proxy_server ~= 'nil' then
        table.insert(outbounds_table, gen_outbound(http_proxy.proxy_server, 'http', 2091))
    end
    table.insert(rules_table, (http_proxy.proxy_server ~= nil and http_proxy.proxy_server ~= 'nil') and {type = 'field',inboundTag = {'http'},outboundTag = 'http'} or nil)
end

if dns_proxy.enable_server == '1' then
    if dns_proxy.proxy_server ~= nil and dns_proxy.proxy_server ~= 'nil' then
        table.insert(outbounds_table, gen_outbound(dns_proxy.proxy_server, 'dns', 2092))
    end
    table.insert(rules_table, (dns_proxy.proxy_server ~= nil and dns_proxy.proxy_server ~= 'nil') and {type = 'field',inboundTag = {'dns'},outboundTag = 'dns'} or nil)
end


table.insert(outbounds_table, gen_bt_outbounds())
table.insert(rules_table, bt_rules)
table.insert(rules_table, bt_rules1)

local v2ray = {
    log = {
        -- error = "/var/vssrsss.log",
        -- access = "/var/v2rays.log",
        loglevel = 'warning'
    },
    -- 传入连接
    inbounds = {
        {
            port = tonumber(local_port),
            protocol = 'dokodemo-door',
            settings = {network = proto, followRedirect = true},
            sniffing = {enabled = true, destOverride = {'http', 'tls'}},
            streamSettings = {
                sockopt = {tproxy = (proto == 'tcp') and 'redirect' or 'tproxy'}
            }
        }
    },
    -- 传出连接
    outbounds = outbounds_table,
    routing = {domainStrategy = 'IPIfNonMatch', rules = rules_table}
}

if global.combine_v2ray_client == '1' and ( global.udp_relay_server == 'same' or global.udp_relay_server == global.global_server ) then
    local udp_relay = {
        port = 1234,
        protocol = 'dokodemo-door',
        streamSettings = {
            sockopt = {
                tproxy = 'tproxy'
            }
        },
        sniffing = {
            enabled = true,
            destOverride = {
                'http',
                'tls'
            }
        },
        settings = {
            network = 'udp',
            followRedirect = true
        }
    }
    table.insert(v2ray.inbounds, udp_relay)
end

if global.combine_v2ray_client == '1' and proto ~= 'udp' then
    if socks5_proxy.enable_server == '1' then
        local sock5 = {
            tag = 'socks5',
            sniffing = {
                enabled = false,
                destOverride = {
                    'http',
                    'tls'
                }
            },
            port = tonumber(socks5_proxy.local_port),
            protocol = 'socks',
            settings = {
                userLevel = 0,
                udp = true,
                accounts = {},
                ip = '0.0.0.0',
                auth = 'noauth'
            }
        }
        if socks5_proxy.enable_auth == '1' and socks5_proxy.Socks_user ~= '' and socks5_proxy.Socks_pass ~= '' and socks5_proxy.Socks_user ~= nil and socks5_proxy.Socks_pass ~= nil then
            sock5.settings.auth = 'password'
            sock5.settings.accounts = {
                {
                    user = socks5_proxy.Socks_user,
                    pass = socks5_proxy.Socks_pass
                }
            }
        end
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
            sock5.settings.auth = 'password'
            sock5.settings.accounts = {
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
            listen = "0.0.0.0",
            settings = {
                address = dns_proxy.server_addr,
                port = tonumber(dns_proxy.server_port),
                network = 'tcp,udp',
                timeout = 0,
                followRedirect = false
            }
        }
        table.insert(v2ray.inbounds,dns)
    end
end

print(json.stringify(v2ray, 1))
