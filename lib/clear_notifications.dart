import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
  // 清除所有通知
  await notifications.cancelAll();
  
  print('所有通知已清除！');
  
  // 退出应用
  exit(0);
}
