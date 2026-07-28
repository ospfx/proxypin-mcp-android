# ProxyPin MCP（安卓版）

[English](README.md) | 中文

> **本仓库是 [ProxyPin](https://github.com/wanghongenpin/proxypin) 的 MCP 增强版，仅支持 Android 平台。**
> 在保留原版全部抓包功能的基础上，内置了完整的 **MCP Server（Model Context Protocol）**，让 AI（Claude、Cursor、Windsurf 等）能够直接连接安卓设备上运行的代理，读取抓包数据，并主动操控拦截与改包——无需任何额外服务或 Python 脚本。

---

## 功能特性

- **HTTP/HTTPS 抓包**：基于 VPN 的安卓全量抓包与 HTTPS 解密（无需设置系统代理）
- **内置 MCP Server**：AI 可实时查看、分析、修改并放行你的流量
- **扫码互联**：其他手机扫码即可连接，无需手动配置 Wi-Fi 代理
- **域名过滤**：只拦截你关心的流量
- **请求搜索**：关键词、Content-Type、多条件组合搜索
- **JavaScript 脚本**：动态修改请求/响应
- **请求重写**：重定向、替换 Body、修改 Header/参数
- **请求映射**：用本地文件/脚本替代远程服务器响应
- **请求解密**：配置 AES 密钥自动解密报文
- **请求屏蔽**：按 URL 规则屏蔽请求
- **断点拦截**：类 Fiddler 断点，可由 AI 控制
- **历史记录**：自动保存抓包数据，支持 HAR 导入导出

---

## MCP Server

> **一句话**：打开 ProxyPin，AI 就能看到你在抓什么包，并且能帮你分析、改包、放行——就像 Fiddler 断点，但由 AI 控制。

### 连接方式

MCP Server 默认监听 **9099** 端口（SSE 传输协议，无需额外依赖）。端口可在 App 内修改（工具箱 → MCP Server），修改后会自动保存，重启不丢失。

在 Claude Desktop / Cursor / Windsurf 中配置：

```json
{
  "mcpServers": {
    "proxypin": {
      "url": "http://127.0.0.1:9099/sse"
    }
  }
}
```

> 在手机上运行？使用设备 IP（如 `http://192.168.1.5:9099/sse`），或通过 `adb forward tcp:9099 tcp:9099` 转发到电脑。

---

### 已实现的 MCP 工具（25 个）

#### 一、基础抓包查询（9 个）

| 工具 | 说明 |
|------|------|
| `get_request_list` | 获取请求列表，支持按域名/方法/状态码/关键词过滤、分页 |
| `get_request_detail` | 获取单条请求完整详情（请求头、请求体、响应头、响应体、耗时） |
| `get_request_body` | 单独获取大体积请求体或响应体原始内容 |
| `get_request_stats` | 统计摘要：域名分布、状态码分布、方法分布、平均耗时 |
| `search_requests` | 高级搜索：URL/Body/Header 关键词 + 时间范围多条件组合 |
| `get_domain_summary` | 按域名分组汇总：路径列表、方法分布、平均耗时 |
| `get_cookie_info` | 提取分析指定域名的 Cookie/Set-Cookie 及属性 |
| `compare_requests` | 对比两条请求的 URL/Header/Body/状态码差异 |
| `analyze_encrypted_content` | 检测 Base64/Hex/URL编码/JWT，计算信息熵，推测加密算法 |

#### 二、请求重放与代码生成（2 个）

| 工具 | 说明 |
|------|------|
| `replay_request` | 重放指定请求，可临时覆盖 Headers/Body，返回真实响应（改包测试） |
| `generate_code` | 将抓包请求转成 Python / JavaScript / cURL / Go 可执行代码 |

#### 三、断点拦截·改包放行（5 个，核心）

> 类似 Fiddler 的断点功能，但由 AI 控制修改后放行。

| 工具 | 说明 |
|------|------|
| `add_breakpoint` | 添加断点规则（URL 正则 + HTTP 方法 + 拦截请求或响应阶段） |
| `list_breakpoints` | 列出所有规则及启用状态 |
| `remove_breakpoint` | 按索引删除规则 |
| `get_pending_intercepts` | 查看当前被暂停等待放行的请求/响应（含完整数据） |
| `release_intercept` | 放行拦截（可修改 Headers、Body、状态码，或直接中止） |

**典型工作流：**
```
AI → add_breakpoint url=".*api/login.*"
   在 App 中触发登录
AI → get_pending_intercepts        ← 读取完整的拦截请求
AI → release_intercept requestId=xxx body='{"user":"admin","pass":"test"}'
   修改后的请求被转发到服务器
```

#### 四、重写规则管理（3 个）

| 工具 | 说明 |
|------|------|
| `list_rewrite_rules` | 列出所有持久化重写规则 |
| `add_rewrite_rule` | 添加规则：替换 Body/Header、修改参数、重定向（5 种类型） |
| `remove_rewrite_rule` | 按索引删除规则 |

#### 五、JS 脚本管理（3 个）

| 工具 | 说明 |
|------|------|
| `list_scripts` | 列出所有 JS 拦截脚本 |
| `get_script_content` | 读取脚本源码 |
| `create_or_update_script` | AI 编写/更新包含 `onRequest`/`onResponse` 的 JS 脚本，立即生效 |

#### 六、安全分析（3 个）

| 工具 | 说明 |
|------|------|
| `find_sensitive_data` | 扫描手机号、身份证、邮箱、JWT、Bearer Token、API Key、密码、内网 IP |
| `analyze_auth` | 提取 Auth Header、API Key Header、Cookie 会话 Token，自动解码 JWT 载荷 |
| `extract_api_endpoints` | 归组 API 路径（ID/UUID 替换为占位符），统计调用次数与状态码 |

---

## 下载与构建

### GitHub Actions 构建（推荐）

推送 `v*` 标签，CI 自动构建通用 release APK 并附加到 GitHub Release：

```bash
git tag v1.3.1
git push origin v1.3.1
# GitHub Actions 自动构建 proxypin-mcp-android-{ver}.apk
```

工作流：`.github/workflows/release.yml`（仅 Android）。

### 安卓签名（可选）

在 GitHub → Settings → Secrets → Actions 中配置以下 Secret 启用 release 签名：

| Secret | 说明 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 your.keystore` 的输出 |
| `ANDROID_STORE_PASSWORD` | storePassword |
| `ANDROID_KEY_ALIAS` | keyAlias |
| `ANDROID_KEY_PASSWORD` | keyPassword |

未配置时自动回退为 debug 签名（可侧载安装，不可上架 Play 商店）。

### 本地构建

环境要求：Flutter **3.44.8+**（Dart ≥ 3.12.2）、Android SDK、Java 17。

```bash
flutter pub get
flutter gen-l10n
flutter build apk --release        # 通用 APK
# 输出：build/app/outputs/flutter-apk/app-release.apk
```

---

## 项目结构

```
android/            安卓平台层（VPN、画中画、应用列表、进程信息插件）
lib/
  main.dart         App 入口（Android）
  network/          代理核心：抓包、TLS 中间人、拦截器链
    mcp/            MCP Server 与工具实现
  ui/mobile/        安卓 UI
  storage/          历史记录 / 收藏持久化
assets/             CA 证书、图标、内置 JS
```

---

## 同步上游

```bash
git fetch upstream
git merge upstream/main
git push origin mcp-main
```

---

## 上游项目

原版 ProxyPin：[https://github.com/wanghongenpin/proxypin](https://github.com/wanghongenpin/proxypin)
感谢 [@wanghongenpin](https://github.com/wanghongenpin) 的优秀原作。

---

## 许可证

Apache License 2.0，与上游项目一致。
<img alt="image"  width="580px" height="420px"  src="https://github.com/user-attachments/assets/6c1345ab-c95c-415d-ac59-470c764b59a2">.<img alt="image"  height="500px" src="https://github.com/user-attachments/assets/3c5572b0-a9e5-497c-8b42-f935e836c164">
