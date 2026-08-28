/*
 * Copyright 2024 Hongen Wang All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:proxypin/l10n/app_localizations.dart';
import 'package:proxypin/network/mcp/mcp_server.dart';
import 'package:proxypin/utils/ip.dart';

/// MCP Server 管理页面
/// 允许用户启动/停止 MCP Server，查看连接配置信息
class McpServerPage extends StatefulWidget {
  const McpServerPage({super.key});

  @override
  State<McpServerPage> createState() => _McpServerPageState();
}

class _McpServerPageState extends State<McpServerPage> {
  final McpServer _mcpServer = McpServer.instance;
  final TextEditingController _portController = TextEditingController();
  bool _isLoading = false;
  bool _autoStart = true;
  bool _allowLanAccess = false;
  String _lanIp = '127.0.0.1';

  AppLocalizations get localizations => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    // 读取本地保存的端口，没有再默认 9010
    McpServer.loadPort().then((savedPort) {
      if (savedPort != null && savedPort != _mcpServer.port) {
        _mcpServer.port = savedPort;
      }
      if (mounted) {
        setState(() {
          _portController.text = _mcpServer.port.toString();
        });
      } else {
        _portController.text = _mcpServer.port.toString();
      }
    });
    // 读取自动启动开关
    McpServer.loadAutoStart().then((enabled) {
      if (mounted) {
        setState(() {
          _autoStart = enabled;
        });
      } else {
        _autoStart = enabled;
      }
    });
    // 读取局域网访问开关
    McpServer.loadAllowLanAccess().then((enabled) async {
      if (enabled) {
        await _loadLanIp();
      }
      if (mounted) {
        setState(() {
          _allowLanAccess = enabled;
          _mcpServer.allowLanAccess = enabled;
        });
      } else {
        _allowLanAccess = enabled;
        _mcpServer.allowLanAccess = enabled;
      }
    });
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态卡片 + 端口配置
              _buildStatusCard(theme, isDark),
              const SizedBox(height: 16),

              // 连接信息
              if (_mcpServer.isRunning) ...[
                _buildConnectionInfo(theme, isDark),
                const SizedBox(height: 16),
              ],

              // AI 配置指南
              _buildConfigGuide(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// 状态卡片（含端口配置）
  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final isRunning = _mcpServer.isRunning;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRunning ? Colors.green.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行：图标 + 标题 + 状态 + 按钮
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? Colors.green.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.hub_outlined,
                    color: isRunning ? Colors.green : theme.iconTheme.color?.withValues(alpha: 0.5),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MCP Server', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isRunning ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isRunning ? localizations.mcpRunning(_mcpServer.port) : localizations.mcpStopped,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isRunning ? Colors.green : theme.textTheme.bodySmall?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.icon(
                        onPressed: _toggleServer,
                        icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 18),
                        label: Text(isRunning ? localizations.stop : localizations.start),
                        style: FilledButton.styleFrom(
                          backgroundColor: isRunning ? Colors.red.shade400 : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            // 端口配置行
            Row(
              children: [
                Icon(Icons.settings_ethernet, size: 18, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Text('${localizations.port}:', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    enabled: !isRunning,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final port = int.tryParse(value);
                      if (port != null && port > 0 && port < 65536) {
                        _mcpServer.port = port;
                      }
                    },
                  ),
                ),
                if (isRunning) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      localizations.mcpStopToChange,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade400, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // 自动启动开关
            Row(
              children: [
                Icon(Icons.power_settings_new, size: 18, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizations.mcpAutoStart, style: theme.textTheme.bodyMedium),
                      Text(localizations.mcpAutoStartDesc,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.hintColor)),
                    ],
                  ),
                ),
                Switch(
                  value: _autoStart,
                  onChanged: (value) {
                    setState(() {
                      _autoStart = value;
                    });
                    McpServer.saveAutoStart(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 局域网访问开关
            Row(
              children: [
                Icon(Icons.wifi, size: 18, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizations.mcpAllowLanAccess, style: theme.textTheme.bodyMedium),
                      Text(localizations.mcpAllowLanAccessDesc,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.hintColor)),
                      if (isRunning)
                        Text(localizations.mcpStopToChangeLanAccess,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade400, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: _allowLanAccess,
                  onChanged: isRunning
                      ? null
                      : (value) async {
                          if (value) {
                            await _loadLanIp();
                          }
                          setState(() {
                            _allowLanAccess = value;
                            _mcpServer.allowLanAccess = value;
                          });
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 连接信息
  Widget _buildConnectionInfo(ThemeData theme, bool isDark) {
    final localIp = _allowLanAccess ? _lanIp : '127.0.0.1';
    final mcpUrl = 'http://$localIp:${_mcpServer.port}/mcp';
    final sseUrl = 'http://$localIp:${_mcpServer.port}/sse';

    final configJson = '''{
  "mcpServers": {
    "proxypin": {
      "url": "$mcpUrl"
    }
  }
}''';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(localizations.mcpConnectionInfo, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // Streamable HTTP URL（最新 MCP 协议）
            _buildCopyableField(theme, 'Streamable HTTP (推荐)', mcpUrl, isDark),
            const SizedBox(height: 10),

            // SSE URL（旧版兼容）
            _buildCopyableField(theme, 'SSE Endpoint (旧版)', sseUrl, isDark),
            const SizedBox(height: 10),

            // Health URL
            _buildCopyableField(theme, 'Health Check', 'http://$localIp:${_mcpServer.port}/health', isDark),
            const SizedBox(height: 12),

            // MCP 配置 JSON
            Text('MCP ${localizations.config} (JSON)', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  SelectableText(
                    configJson,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark ? Colors.green.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(configJson),
                      tooltip: AppLocalizations.of(context)!.copy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 可复制字段
  Widget _buildCopyableField(ThemeData theme, String label, String value, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              value,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blue.shade300),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.copy, size: 14),
          onPressed: () => _copyToClipboard(value),
          tooltip: AppLocalizations.of(context)!.copy,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  /// AI 配置指南
  Widget _buildConfigGuide(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(localizations.mcpConfigGuide,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideItem(theme, '1', localizations.mcpGuideStep1),
            _buildGuideItem(theme, '2', localizations.mcpGuideStep2),
            _buildGuideItem(theme, '3', localizations.mcpGuideStep3),
            const SizedBox(height: 8),
            Text('${localizations.mcpAvailableTools}:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _buildToolItem(theme, 'get_request_list', localizations.mcpToolListDesc),
            _buildToolItem(theme, 'get_request_detail', localizations.mcpToolDetailDesc),
            _buildToolItem(theme, 'get_request_stats', localizations.mcpToolStatsDesc),
            _buildToolItem(theme, 'search_requests', localizations.mcpToolSearchDesc),
            _buildToolItem(theme, 'get_request_body', localizations.mcpToolBodyDesc),
            _buildToolItem(theme, 'analyze_encrypted_content', localizations.mcpToolAnalyzeDesc),
            _buildToolItem(theme, 'get_domain_summary', localizations.mcpToolDomainDesc),
            _buildToolItem(theme, 'get_cookie_info', localizations.mcpToolCookieDesc),
            _buildToolItem(theme, 'compare_requests', localizations.mcpToolCompareDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(ThemeData theme, String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(step,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildToolItem(ThemeData theme, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.build_circle_outlined, size: 12, color: theme.iconTheme.color?.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(name,
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade300)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(desc,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  /// 启动/停止服务器
  Future<void> _toggleServer() async {
    setState(() => _isLoading = true);

    try {
      if (_mcpServer.isRunning) {
        await _mcpServer.stop();
        if (mounted) FlutterToastr.show(localizations.mcpStopSuccess, context);
      } else {
        final port = int.tryParse(_portController.text);
        if (port == null || port <= 0 || port >= 65536) {
          if (mounted) FlutterToastr.show(localizations.mcpInvalidPort, context);
          return;
        }
        _mcpServer.port = port;
        await _mcpServer.start();
        // 端口可能因占用自动递增，同步显示实际端口
        _portController.text = _mcpServer.port.toString();
        if (mounted) FlutterToastr.show(localizations.mcpStartSuccess(_mcpServer.port), context);
      }
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        if (msg.contains('Failed to create server socket') || msg.contains('address already in use')) {
          FlutterToastr.show('${localizations.port} ${_mcpServer.port} ${localizations.mcpInvalidPort}', context);
        } else {
          FlutterToastr.show('Error: $msg', context);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) FlutterToastr.show(localizations.copied, context);
  }

  Future<void> _loadLanIp() async {
    try {
      final ip = await localIp();
      if (mounted) {
        setState(() {
          _lanIp = ip;
        });
      } else {
        _lanIp = ip;
      }
    } catch (e) {
      _lanIp = '127.0.0.1';
    }
  }
}
