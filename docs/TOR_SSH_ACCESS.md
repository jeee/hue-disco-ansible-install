# Optional SSH access over Tor

The installer can optionally install Tor and expose the Raspberry Pi's local SSH service as a Tor v3 onion service.

This is **disabled by default**. Enable it only when you explicitly want SSH reachable through Tor.

## Minimal config

In your local ignored `group_vars/all.yml`:

```yaml
tor_ssh:
  enabled: true
```

Then run:

```bash
ansible-playbook -i inventory.ini site.yml
```

The role installs `tor` and `openssh-server`, enables `ssh.service`, and adds this managed block to `/etc/tor/torrc`:

```text
HiddenServiceDir /var/lib/tor/hue-disco-ssh
HiddenServiceVersion 3
HiddenServicePort 22 127.0.0.1:22
```

## Where the onion address is stored

On the Pi:

```text
/var/lib/hue-disco/tor_ssh_onion_address
/var/lib/hue-disco/tor_ssh_onions.txt
```

On the Ansible controller, the address is appended to this ignored local file if it is not already present:

```text
./tor_ssh_onions.txt
```

This makes repeated installs safe: existing addresses are not duplicated, and multiple different installs can be collected in the same local list.

## Connecting

From a machine with Tor client tools:

```bash
torsocks ssh <user>@<onion-address>
```

Example:

```bash
torsocks ssh pi@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefgh.onion
```

## Optional overrides

```yaml
tor_ssh:
  enabled: true
  virtual_port: 22
  target_host: 127.0.0.1
  target_port: 22
  hidden_service_dir: /var/lib/tor/hue-disco-ssh
  target_onion_address_file: /var/lib/hue-disco/tor_ssh_onion_address
  target_onion_list_file: /var/lib/hue-disco/tor_ssh_onions.txt
  store_on_controller: true
  local_onion_list_path: "{{ playbook_dir }}/tor_ssh_onions.txt"
  hostname_wait_seconds: 90
```

## Security note

The onion service exposes SSH authentication to the Tor network. Use key-based SSH auth, strong user passwords if passwords remain enabled, and avoid exposing accounts you do not need.
