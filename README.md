# ProxyPin MCP (Android)

English | [中文](README_CN.md)

> **This repo is an MCP-enhanced, Android-only fork of [ProxyPin](https://github.com/wanghongenpin/proxypin).**
> It ships a built-in **MCP Server (Model Context Protocol)** on top of the full original capture feature set, letting AI clients (Claude, Cursor, Windsurf, etc.) connect directly to the running proxy on your Android device, read capture data, and actively control interception and modification — no extra service or Python script needed.

---

## Features

- **HTTP/HTTPS capture**: full packet capture and HTTPS decryption on Android (VPN-based, no system proxy needed)
- **Built-in MCP Server**: AI can see, analyze, modify and release your traffic in real time
- **QR code device pairing**: connect other phones without manual Wi-Fi proxy config
- **Domain filtering**: intercept only the traffic you need
- **Request search**: keyword, content-type, multi-condition search
- **JavaScript scripts**: dynamic request/response manipulation
- **Request rewrite**: redirect, replace body, modify headers/params
- **Request mapping**: respond with local files/scripts instead of remote server
- **Request decryption**: AES key auto-decrypts message bodies
- **Request blocking**: block requests by URL pattern
- **Breakpoint interception**: Fiddler-style breakpoints, controllable by AI
- **History**: auto-save capture data; HAR import/export

---

## MCP Server

> **TL;DR**: Open ProxyPin, and AI can see every request you capture, help you analyze it, modify it, and release it — like Fiddler breakpoints, but controlled by AI.

### Connection

The MCP Server listens on port **9099** by default (SSE transport, no extra dependencies required). The port is configurable in the app (Toolbox → MCP Server) and is persisted across restarts.

Configure in Claude Desktop / Cursor / Windsurf:

```json
{
  "mcpServers": {
    "proxypin": {
      "url": "http://127.0.0.1:9099/sse"
    }
  }
}
```

> Running on a phone? Use the device IP (e.g. `http://192.168.1.5:9099/sse`) or `adb forward tcp:9099 tcp:9099`.

---

### Available MCP Tools (25 total)

#### 1. Basic Capture Query (9 tools)

| Tool | Description |
|------|-------------|
| `get_request_list` | List captured requests with filters: domain, method, status code, keyword, pagination |
| `get_request_detail` | Full details of a single request: headers, body, response, timing |
| `get_request_body` | Fetch large request/response body content directly |
| `get_request_stats` | Summary stats: domain distribution, status codes, methods, avg latency |
| `search_requests` | Advanced search: URL/Body/Header keyword + time range |
| `get_domain_summary` | Group by domain: unique paths, method distribution, avg latency |
| `get_cookie_info` | Extract Cookie/Set-Cookie headers and analyze attributes |
| `compare_requests` | Diff two requests: URL, Headers, Query params, Body, Status code |
| `analyze_encrypted_content` | Detect Base64/Hex/URL-encoded/JWT content, compute entropy, hint at algorithm |

#### 2. Replay & Code Generation (2 tools)

| Tool | Description |
|------|-------------|
| `replay_request` | Replay a captured request with optional header/body overrides; returns the live response |
| `generate_code` | Convert a captured request to runnable code: Python / JavaScript / cURL / Go |

#### 3. Breakpoint Interception · Modify & Release (5 tools, highlight)

> Fiddler-style breakpoints, but controlled by AI conversation.

| Tool | Description |
|------|-------------|
| `add_breakpoint` | Add a breakpoint rule (URL regex + HTTP method + request/response phase) |
| `list_breakpoints` | List all rules and their enabled state |
| `remove_breakpoint` | Remove a rule by index |
| `get_pending_intercepts` | View all currently paused requests/responses with full data |
| `release_intercept` | Release an intercept with optional modifications: Headers, Body, StatusCode, or abort |

**Typical workflow:**
```
AI → add_breakpoint url=".*api/login.*"
   Trigger login in the App
AI → get_pending_intercepts        ← reads the full intercepted request
AI → release_intercept requestId=xxx body='{"user":"admin","pass":"test"}'
   The modified request is forwarded to the server
```

#### 4. Rewrite Rule Management (3 tools)

| Tool | Description |
|------|-------------|
| `list_rewrite_rules` | List all persistent rewrite rules |
| `add_rewrite_rule` | Add a rule: replace body/headers, update params, redirect (5 types) |
| `remove_rewrite_rule` | Remove a rule by index |

#### 5. JS Script Management (3 tools)

| Tool | Description |
|------|-------------|
| `list_scripts` | List all JS intercept scripts |
| `get_script_content` | Read script source code |
| `create_or_update_script` | AI writes/updates a JS script with `onRequest`/`onResponse`; takes effect immediately |

#### 6. Security Analysis (3 tools)

| Tool | Description |
|------|-------------|
| `find_sensitive_data` | Scan for phone numbers, ID cards, emails, JWT, Bearer tokens, API keys, passwords, private IPs |
| `analyze_auth` | Extract Auth headers, API key headers, Cookie session tokens; auto-decode JWT payloads |
| `extract_api_endpoints` | Group and normalize API paths (replace IDs/UUIDs with placeholders), count calls and status codes |

---

## Download & Build

### GitHub Actions (recommended)

Push a `v*` tag and the CI builds a universal release APK and attaches it to a GitHub Release:

```bash
git tag v1.3.1
git push origin v1.3.1
# GitHub Actions builds proxypin-mcp-android-{ver}.apk automatically
```

Workflow: `.github/workflows/release.yml` (Android only).

### Android Signing (optional)

Set these Secrets in GitHub → Settings → Secrets → Actions to enable release signing:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Output of `base64 -w 0 your.keystore` |
| `ANDROID_STORE_PASSWORD` | storePassword |
| `ANDROID_KEY_ALIAS` | keyAlias |
| `ANDROID_KEY_PASSWORD` | keyPassword |

Without these secrets, the build automatically falls back to debug signing (sideloadable, not Play Store ready).

### Local build

Requirements: Flutter **3.44.8+** (Dart ≥ 3.12.2), Android SDK, Java 17.

```bash
flutter pub get
flutter gen-l10n
flutter build apk --release        # universal APK
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project layout

```
android/            Android runner (VPN, PiP, installed apps, process info plugins)
lib/
  main.dart         App entry (Android)
  network/          Proxy core: capture, TLS MITM, interceptors
    mcp/            MCP Server + tools
  ui/mobile/        Android UI
  storage/          History / favorites persistence
assets/             CA cert, icons, JS built-ins
```

---

## Staying in sync with upstream

```bash
git fetch upstream
git merge upstream/main
git push origin mcp-main
```

---

## Upstream

Original ProxyPin: [https://github.com/wanghongenpin/proxypin](https://github.com/wanghongenpin/proxypin)
Thanks to [@wanghongenpin](https://github.com/wanghongenpin) for the excellent original work.

---

## License

Apache License 2.0, same as the upstream project.
<img alt="image"  width="580px" height="420px"  src="https://github.com/user-attachments/assets/6c1345ab-c95c-415d-ac59-470c764b59a2">.<img alt="image"  height="500px" src="https://github.com/user-attachments/assets/3c5572b0-a9e5-497c-8b42-f935e836c164">

### Powered by
[![JetBrains logo.](https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg)](https://jb.gg/OpenSource)
