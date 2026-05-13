# Raspberry Pi network modes for a directly connected Hue bridge

This installer can optionally configure a Raspberry Pi to support a real Hue bridge plugged directly into `eth0` while the Pi uses Wi-Fi as its uplink.

The feature is **disabled by default**. Nothing is changed unless `rpi_network.enabled: true` is set in `group_vars/all.yml`.

## Default behavior

```yaml
rpi_network:
  enabled: false
```

No packages, network services, DHCP server, forwarding rules, or extra IP addresses are configured.

## Auto direct-bridge behavior

When enabled with `mode: auto`, the helper periodically reconciles `eth0` and also reacts to NetworkManager link events:

1. If `eth0` gets a normal DHCP address, it stays in normal client mode.
2. If `eth0` has carrier but no DHCP address after `dhcp_timeout_seconds`, the Pi assumes a direct Hue bridge is attached.
3. The Pi activates a dedicated NetworkManager manual profile for `eth0`, starts DHCP for the bridge, and NATs bridge internet through Wi-Fi.
4. If the cable is unplugged, direct-mode runtime state is cleaned up so the next plug-in can try normal DHCP again first.

Example:

```yaml
rpi_network:
  enabled: true
  mode: auto
  uplink:
    interface: wlan0
  eth:
    interface: eth0
    dhcp_timeout_seconds: 20
  eth_downstream:
    address: 192.168.77.1/24
    dhcp_start: 192.168.77.2
    dhcp_end: 192.168.77.10
    lease_time: 24h
    hue_bridge_ip: 192.168.77.2
```

Result in fallback mode:

```text
Pi wlan0:      normal Wi-Fi DHCP/internet
Pi eth0:       192.168.77.1/24
Hue bridge:    192.168.77.2 from Pi DHCP
Bridge route:  through Pi wlan0 using NAT
```

Hue Disco should use the private bridge IP, usually `192.168.77.2`, as the reliable control/recovery path.

## Optional LAN exposure through a second Wi-Fi DHCP lease

If enabled, the Pi can also ask the Wi-Fi network for a second DHCP lease and forward selected TCP ports to the Hue bridge.

```yaml
rpi_network:
  enabled: true
  mode: auto
  expose_to_lan:
    enabled: true
    mode: dhcp
    dhcp_client_id: hue-bridge-direct
    forwarded_tcp_ports: [80, 443]
```

The helper runs a separate DHCP client on `wlan0` with the configured DHCP client identifier. If the router grants a second lease, the helper adds that IP as `/32` on `wlan0` and installs nftables rules like this:

```text
LAN second IP:  <DHCP-assigned address on wlan0>
Forward to:     192.168.77.2
TCP ports:      80, 443 by default
```

The assigned LAN exposure IP is visible in service logs:

```bash
journalctl -u hue-bridge-direct-net.service
```

Look for:

```text
Hue bridge private IP: 192.168.77.2; LAN exposed IP: x.x.x.x
```

You can also check:

```bash
cat /run/hue-bridge-direct/lan-ip
```

If the second DHCP lease is not granted, the bridge still works privately at `192.168.77.2`; it is just not exposed on the Wi-Fi LAN.

## Static LAN exposure alternative

If you know a safe unused address on the Wi-Fi LAN, static mode avoids guessing which second DHCP lease was granted:

```yaml
rpi_network:
  expose_to_lan:
    enabled: true
    mode: static
    virtual_ip: 192.168.1.51
    forwarded_tcp_ports: [80, 443]
```

## Limitations

The LAN exposure mode is 1:1-ish TCP forwarding/NAT, not a true Wi-Fi/Ethernet layer-2 bridge. It is useful for direct HTTP/HTTPS access to the bridge, but phone app auto-discovery may still be unreliable because Hue discovery can depend on multicast/broadcast protocols that do not behave like simple TCP connections.

For maximum Hue app compatibility, plug the Hue bridge directly into the real LAN/router/switch. For maximum Hue Disco reliability with a direct cable, use the private `eth0` subnet and treat LAN exposure as optional convenience.
