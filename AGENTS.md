# AGENTS.md

HarmonyOS (ArkTS) single-module app. Smart-home / IoT style UI (devices, lights, environment, smoke alarm) that talks to physical hardware over TCP/UDP sockets and Bluetooth.

## Build & run

- Build system is **hvigor**, not npm. There are no npm scripts; do not create a `package.json`.
- Dependencies are managed with **ohpm** (`oh-package.json5`, `oh-package-lock.json5`). Never edit `oh-package-lock.json5` by hand; run `ohpm install` after changing `oh-package.json5`.
- Build/run through DevEco Studio or the hvigor CLI. In this tooling environment use `build_project` (debug mode) then `start_app`.
- Product name is `default`; module is `entry`. Build modes: `debug`, `release`.
- **Signing is machine-specific**: `build-profile.json5` points at debug certs under `C:\Users\Su-Qi\.ohos\config\`. On any other machine, reconfigure signing in DevEco Studio before building; do not commit new cert paths or passwords.

## ArkTS rules (strict mode is ON)

- `strictMode.caseSensitiveCheck` and `useNormalizedOHMUrl` are enabled — import paths and file names must match case exactly.
- No `any`/`unknown`, no `as` casts, no untyped object literals, no dynamic property access (`obj[key]`). Structs/components only via `@Component`/`struct`, not classes with UI.
- Lint config is `code-linter.json5`: lints only `**/*.ets`, and all `@security/no-unsafe-*` crypto rules are hard errors. Don't weaken them.
- After editing any `.ets` file, run a fast static check (`arkts_check`) before a full build — much faster feedback than `build_project`.

## Architecture

- Entry point: `EntryAbility` (`entry/src/main/ets/entryability/EntryAbility.ets`) loads `pages/Homepage`.
- `pages/Homepage.ets` is a 3-tab shell (设备 / 生活 / 我的) composed of components in `entry/src/main/ets/pages/view/` (`Facility`, `Dailylife`, `MineContent`). Feature pages (`Light`, `Environment`, `Smokealarm`, `Monitor`, …) live in `entry/src/main/ets/pages/`.
- **Adding a page requires two steps**: create the `.ets` file under `entry/src/main/ets/pages/` AND register its route in `entry/src/main/resources/base/profile/main_pages.json`. A missing registration means the page silently fails to route.
- Networking helpers live in `entry/src/main/ets/tools/`:
  - `server.ets` is the canonical TCP/UDP protocol implementation (v2.2.0): TCP connect → auto-listen → data via `setOnTcpData` callback or `mass` field; UDP device discovery on port 5000 (`startUdpDiscovery`/`setOnDeviceFound`); parses `"设备名,数据1,数据2,..."` into `IoTDeviceData`; exports singleton `server`. `s.ets` is a stale near-duplicate of the old v1 class — don't extend it.
  - `tcp_on.ets` registers a global `tcp.on('message')` listener **at module import time** (module-level side effect) and is disconnected from UI state. Importing it anywhere starts listening.
- `Bluetooth.ets` implements BLE provisioning (`Esp32BleService`, singleton `esp32BleService`): scan (`startScan`, filters ESP32/Provision names), GATT connect, write Wi-Fi credentials JSON. Requires `ohos.permission.ACCESS_BLUETOOTH` (user_grant, reason + usedScene declared in `module.json5`).

## Known repo quirks

- `entry/src/main/module.json5` → `requestPermissions` previously had duplicate `"name"` keys (fixed 2026-09); permissions are now split into separate objects: `INTERNET`, `USE_BLUETOOTH`, `ACCESS_BLUETOOTH` (with reason/usedScene). Don't merge them back into one object.
- Several pages are exploratory/WIP with large commented-out blocks: `receDataTest.ets` (entire page commented out but still registered in `main_pages.json`), `test.ets`, `test2.ets`, parts of `tcp_on.ets`. Don't assume registered pages are working features.
- `entry/src/test/` and `entry/src/ohosTest/` are untouched hypium/hamock scaffolding — there are no real tests. Testing networking/Bluetooth features requires a real device (or a LAN peer for socket tests); emulators have limited Bluetooth support.

## Permissions & runtime

- Network (`@kit.NetworkKit` socket) and Bluetooth code requires the permissions above plus a real device for end-to-end verification. TCP defaults (`tcpAddress: ''`, `tcpPort: 80`) are placeholders — real target IP/port are entered in the UI at runtime.
