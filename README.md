# hue-disco-ansible-install

Ansible provisioning repo for installing the Hue/Zigbee stack on a target host.

## Local setup

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ansible-playbook -i inventories/example/hosts.yml playbook.yml --check
```

Adjust inventory before running against a real host.
