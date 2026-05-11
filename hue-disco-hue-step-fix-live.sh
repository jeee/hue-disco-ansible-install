#!/usr/bin/env bash
set -euo pipefail

CFG=/opt/hue-disco/config.yaml
SCHEMA=/opt/hue-disco/config_schema.py

sudo cp -an "$CFG" "$CFG.bak.$(date +%Y%m%d-%H%M%S)" || true
sudo cp -an "$SCHEMA" "$SCHEMA.bak.$(date +%Y%m%d-%H%M%S)" || true

sudo python3 - <<'PY2'
from pathlib import Path
import yaml

cfg_path = Path('/opt/hue-disco/config.yaml')
data = yaml.safe_load(cfg_path.read_text()) or {}
legacy = data.get('hue_disco') if isinstance(data.get('hue_disco'), dict) else {}
keys = [
    'sample_rate', 'block_size', 'sensitivity', 'min_interval_ms', 'energy_decay',
    'beat_prediction_ms', 'beat_subdivision', 'change_every_beats', 'accent_every_beats',
    'hue_step', 'strobe_seconds', 'audio_device'
]
for key in keys:
    if key not in data and key in legacy:
        data[key] = legacy[key]

data['hue_step'] = 18
legacy['hue_step'] = 18
if legacy:
    data['hue_disco'] = legacy

cfg_path.write_text(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
print('root hue_step =', data.get('hue_step'))
print('nested hue_step =', data.get('hue_disco', {}).get('hue_step'))
PY2

sudo python3 - <<'PY2'
from pathlib import Path
p = Path('/opt/hue-disco/config_schema.py')
s = p.read_text()
if "'hue_step': 0.12" in s:
    s = s.replace("'hue_step': 0.12", "'hue_step': 18")
if '_merge_legacy_hue_disco' not in s:
    s = s.replace(
        "DEFAULTS = {",
        "LEGACY_ROOT_KEYS = {\n    'sample_rate', 'block_size', 'sensitivity', 'min_interval_ms', 'energy_decay',\n    'beat_prediction_ms', 'beat_subdivision', 'change_every_beats', 'accent_every_beats',\n    'hue_step', 'strobe_seconds', 'audio_device'\n}\n\nDEFAULTS = {"
    )
    s = s.replace(
        "def load_config(path):\n    data = yaml.safe_load(Path(path).read_text(encoding='utf-8')) or {}\n    merged = dict(DEFAULTS)\n    merged.update(data)",
        "def _merge_legacy_hue_disco(data):\n    legacy = data.get('hue_disco') if isinstance(data, dict) else None\n    if isinstance(legacy, dict):\n        for key in LEGACY_ROOT_KEYS:\n            if key in legacy and key not in data:\n                data[key] = legacy[key]\n    return data\n\n\ndef load_config(path):\n    data = yaml.safe_load(Path(path).read_text(encoding='utf-8')) or {}\n    data = _merge_legacy_hue_disco(data)\n    merged = dict(DEFAULTS)\n    merged.update(data)"
    )
    s = s.replace(
        "def save_config(path, cfg):\n    if not cfg.get('psk_identity') and cfg.get('app_key'):\n        cfg['psk_identity'] = cfg['app_key']\n    Path(path).write_text(yaml.safe_dump(cfg, sort_keys=False, allow_unicode=True), encoding='utf-8')",
        "def save_config(path, cfg):\n    if not cfg.get('psk_identity') and cfg.get('app_key'):\n        cfg['psk_identity'] = cfg['app_key']\n    cfg = dict(cfg)\n    cfg.pop('hue_disco', None)\n    Path(path).write_text(yaml.safe_dump(cfg, sort_keys=False, allow_unicode=True), encoding='utf-8')"
    )
p.write_text(s)
print('patched', p)
PY2

sudo systemctl restart hue-disco
sleep 2
curl -s -u 'x:disco-control' http://127.0.0.1:8090/status || true
