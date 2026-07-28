# AGENTS.md

## What This Project Is
- `proxypin` is a Flutter **Android** app with an in-process HTTP(S) proxy core; UI and proxy run in the same app process (`lib/main.dart`, `lib/network/bin/server.dart`).
- This fork adds a built-in **MCP Server** (`lib/network/mcp/`) exposing capture data and interception control to AI clients. Transports: Streamable HTTP at `/mcp` (protocol `2025-06-18`, recommended) and legacy HTTP+SSE at `/sse` (protocol `2024-11-05`). Default port 9010.
- Primary value flows are capture -> mutate -> inspect -> persist traffic. Android is the only supported platform.

## Architecture You Need First
- Entry point boots the mobile shell directly (`lib/main.dart` -> `lib/ui/mobile/mobile.dart`).
- Proxy server lifecycle is owned by `ProxyServer` (start/stop/restart, cert init) (`lib/network/bin/server.dart`).
- Socket/channel pipeline lives in `Server`/`Network`; TLS MITM handshake and relay fallbacks happen in `Server.ssl` (`lib/network/channel/network.dart`).
- HTTP request/response routing is centralized in `HttpProxyChannelHandler` and `HttpResponseProxyHandler` (`lib/network/handle/http_proxy_handle.dart`).
- UI pages implement `EventListener` to receive `onRequest/onResponse/onMessage` events from proxy runtime (`lib/ui/mobile/mobile.dart`, `lib/network/bin/listener.dart`).
- MCP Server binds on app start and reads capture data from the request container (`lib/network/mcp/mcp_server.dart`, `lib/network/mcp/mcp_tools.dart`); breakpoint MCP tools bridge via `McpInterceptQueue` (`lib/network/mcp/`).

## Interceptor Model (Core Convention)
- All traffic mutations use `Interceptor` hooks: `preConnect`, `onRequest`, `execute`, `onResponse`, `onError` (`lib/network/components/interceptor.dart`).
- Interceptors are sorted by `priority` before registration; changing order changes behavior (`lib/network/bin/server.dart`).
- Current chain includes hosts, request-map, rewrite, JS script, block, breakpoint, report-server (`lib/network/bin/server.dart`).
- `execute()` can short-circuit remote calls by returning a synthetic `HttpResponse` (used by request mapping) (`lib/network/components/request_map.dart`).

## Persistence + Config Patterns
- Network/runtime config is JSON in app support paths (not in repo): `config.cnf`, `request_rewrite.json`, `request_map.json`, `script.json` (`lib/network/bin/configuration.dart`, `lib/network/components/manager/*`).
- UI preferences are separate from proxy config (`ui_config.json`) (`lib/ui/configuration.dart`).
- Captured traffic is persisted as HAR-like records via `HistoryStorage` and periodic `HistoryTask` flushes (`lib/storage/histories.dart`, `lib/utils/har.dart`).
- Favorites intentionally trim websocket/SSE frame count and payload size before persistence (`lib/storage/favorites.dart`).

## Platform Integration Boundaries
- Android native plugins are registered in `MainActivity` (VPN, PiP, lifecycle, installed apps, process info) (`android/app/src/main/kotlin/com/network/proxy/MainActivity.kt`).
- Method channel: `com.proxypin/method` (`lib/native/native_method.dart`).
- Some UI code still contains dormant `Platform.isIOS` branches kept from upstream; they are never taken on Android. Do not add new iOS-only code.

## Developer Workflows That Matter
- Install deps: `flutter pub get`.
- Run app: `flutter run -d android` (proxy boot is triggered from UI init, not a separate daemon).
- Build release APK: `flutter build apk --release` (Flutter 3.44.8+, Java 17). CI: `.github/workflows/release.yml` (Android-only, tag `v*` or manual).
- Run tests: `flutter test` (see protocol-focused tests in `test/`).
- Localization is generated from `lib/l10n` using `l10n.yaml` (`flutter gen-l10n`).

## Project-Specific Guardrails For Agents
- Do not store runtime defaults in source-only constants if equivalent persisted config exists; update the relevant manager/config serializer too.
- When adding traffic features, prefer a new/interposed `Interceptor` instead of branching deep inside handlers.
- Preserve wildcard URL rule semantics (`*` expansion, escaped `?`) used by rewrite/map rule matchers.
- New MCP tools must be registered in `lib/network/mcp/mcp_tools.dart` and documented in both READMEs.
- Keep shared proxy logic in `lib/network/**`; Android UI behavior in `lib/ui/mobile/**` only.
- Ignore generated/build artifacts (`build/`, platform build outputs) unless the task explicitly targets packaging.
