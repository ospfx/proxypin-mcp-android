/*
 * Copyright 2023 Hongen Wang
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
import 'package:proxypin/ui/toolbox/encoder.dart';

/// 窗口打开回调（移动端通过路由导航实现，由 MobileHomePage 注册）
/// 原桌面端多窗口实现已移除。
class MultiWindow {
  static Function(String widgetName, Map<String, dynamic>? args)? onOpenWindow;

  /// 打开窗口：移动端通过 [onOpenWindow] 回调导航到对应页面
  static Future<void> openWindow(String title, String widgetName, {Map<String, dynamic>? args}) async {
    onOpenWindow?.call(widgetName, args);
  }
}

///打开编码页面
Future<void> encodeWindow(EncoderType type, BuildContext context, [String? text]) async {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => EncoderWidget(type: type, text: text)));
}
