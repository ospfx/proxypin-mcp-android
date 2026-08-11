/*
 * Copyright 2023 Hongen Wang All rights reserved.
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
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:proxypin/l10n/app_localizations.dart';
import 'package:proxypin/native/vpn.dart';
import 'package:proxypin/network/bin/server.dart';
import 'package:proxypin/network/util/logger.dart';
import 'package:proxypin/utils/lang.dart';
import 'package:proxypin/utils/platform.dart';

///启动按钮
///@author wanghongen
///2023/10/8
class SocketLaunch extends StatefulWidget {
  static ValueNotifier<ValueWrap<bool>> startStatus = ValueNotifier(ValueWrap());

  final ProxyServer proxyServer;
  final int size;
  final bool startup; //默认是否启动
  final Function? onStart;
  final Function? onStop;

  final bool serverLaunch; //是否启动代理服务器

  const SocketLaunch(
      {super.key,
      required this.proxyServer,
      this.size = 25,
      this.onStart,
      this.onStop,
      this.startup = true,
      this.serverLaunch = true});

  @override
  State<StatefulWidget> createState() => _SocketLaunchState();
}

class _SocketLaunchState extends State<SocketLaunch> with WidgetsBindingObserver {
  AppLocalizations get localizations => AppLocalizations.of(context)!;
  bool started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //启动代理服务器
    if (widget.startup) {
      start();
    }

    SocketLaunch.startStatus.addListener(() {
      if (SocketLaunch.startStatus.value.get() == started) {
        return;
      }
      setState(() {
        started = SocketLaunch.startStatus.value.get() ?? started;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.proxyServer.isRunning && started) {
        widget.proxyServer.retryBind().catchError((e) {
          logger.e('retryBind failed on resumed', error: e);
        });
      }

      if (Platforms.isMobile() && started == false) {
        Vpn.isRunning().then((value) {
          Vpn.isVpnStarted = value;
          SocketLaunch.startStatus.value = ValueWrap.of(value);
        });
      }
    }

    if (state == AppLifecycleState.detached) {
      logger.d('AppLifecycleState.detached');
      widget.onStop?.call();
      widget.proxyServer.stop();
      started = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    return IconButton(
        tooltip: started ? localizations.stop : localizations.start,
        icon: Icon(started ? Icons.stop : Icons.play_arrow_sharp,
            color: started ? Colors.red : primaryColor, size: widget.size.toDouble()),
        onPressed: () async {
          if (started) {
            if (!widget.serverLaunch) {
              setState(() {
                widget.onStop?.call();
                started = !started;
              });
              return;
            }

            widget.proxyServer.stop().then((value) {
              widget.onStop?.call();
              if (mounted) {
                setState(() {
                  started = !started;
                });
              }
            }).catchError((e) {
              logger.e("stop proxy server failed", error: e);
              if (mounted) {
                FlutterToastr.show(localizations.fail, context, duration: 3);
                setState(() {
                  started = false;
                });
              }
            });
          } else {
            start();
          }
        });
  }

  ///启动代理服务器
  Future<void> start() async {
    if (!widget.serverLaunch) {
      await widget.onStart?.call();
      setState(() {
        started = true;
      });
      return;
    }

    widget.proxyServer.start().then((value) {
      setState(() {
        started = true;
      });
      widget.onStart?.call();
    }).catchError((e) {
      logger.e("启动代理服务器失败", error: e);
      String message = localizations.proxyPortRepeat(widget.proxyServer.port);
      FlutterToastr.show(message, context, duration: 3);
    });
  }
}
