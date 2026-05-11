# Next chat handoff — v15 MG21 entertainment-group and DTLS startup fixes

We are continuing from an ansible installer package that already includes the diyHue MG21 entertainment activation fixes discovered during live debugging.

## Treat this archive as the source of truth

The package now already includes these live fixes:

- native MG21 default backend and Zigbee2MQTT disabled by default
- stable diyHue container lifecycle and non-empty entertainment group id
- native light PUT path and IEEE normalization fixes
- native MG21 stream activation now creates a local diyHue `EntertainmentConfiguration` when missing
- native MG21 stream activation now starts diyHue `entertainmentService` and opens UDP 2100
- corrected constructor call `EntertainmentConfiguration.EntertainmentConfiguration(...)`
- Hue Disco DTLS/strobe debug logging is present in the shipped Python sources

## What the next chat should verify first

1. Install or update from this v15 archive.
2. Confirm diyHue group stream activation still succeeds.
3. Confirm UDP 2100 is open after `{"stream":{"active":true}}`.
4. Trigger Hue Disco strobe using the web API.
5. Inspect Hue Disco debug logs from the running service namespace.
6. Re-check `http://127.0.0.1:9123/state` and confirm non-zero entertainment frame counters.
7. Only then continue with lamp-output debugging.

## Important current caveat

The service unit currently uses `PrivateTmp=true`. That means `/tmp/hue-disco-strobe.log` and `/tmp/hue-disco-dtls.log` may exist only inside the service private tmp namespace and may not be visible from the host path `/tmp`. Do not misread a missing host-side file as proof that the code path never executed.

## Remaining focus areas

- verify Hue Disco thread execution after authenticated `/api/control/strobe`
- verify DTLS send path logs are actually being produced by the running service
- verify MG21 native counters advance once Hue Disco sends frames
- verify visible lamp output after counters move

## Files worth reading first

- `RELEASE_NOTES_v15.md`
- `LATEST_STATUS.md`
- `docs/MG21_EXTENSIVE_HANDOFF_v13.md`
- `docs/MG21_CURRENT_INSTALL.md`
