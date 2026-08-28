import 'package:flutter_test/flutter_test.dart';
import 'package:proxypin/network/mcp/mcp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('McpServer LAN access preference', () {
    test('defaults to disabled when preference is missing', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await McpServer.loadAllowLanAccess(), isFalse);
    });

    test('persists allowLanAccess preference', () async {
      SharedPreferences.setMockInitialValues({});

      await McpServer.saveAllowLanAccess(true);
      expect(await McpServer.loadAllowLanAccess(), isTrue);

      await McpServer.saveAllowLanAccess(false);
      expect(await McpServer.loadAllowLanAccess(), isFalse);
    });

    test('autoStartIfEnabled loads persisted LAN mode', () async {
      SharedPreferences.setMockInitialValues({
        'proxyPinMcp_autoStart': false,
        'proxyPinMcp_allowLanAccess': true,
      });

      final server = McpServer.instance;
      server.allowLanAccess = false;
      await server.autoStartIfEnabled();

      expect(server.isRunning, isFalse);
      expect(server.allowLanAccess, isTrue);
    });
  });
}
