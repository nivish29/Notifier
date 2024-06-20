
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // awesomeNotificationService() {
  //   _initializeNotifications();
  // }

  Future<void> initializeNotifications() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
    await AwesomeNotifications().initialize(
      'resource://drawable/res_notification_app_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic notifications',
          icon: 'resource://drawable/res_notification_app_icon',
          playSound: true,
          onlyAlertOnce: true,
          groupAlertBehavior: GroupAlertBehavior.Children,
          importance: NotificationImportance.Default,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
    );
  }

  Future<void> showNotification(String title, String message) async {
    await AwesomeNotifications().cancelAll();
    await AwesomeNotifications().createNotification(
      // actionButtons: [NotificationActionButton(key: 'key1', label: 'open')],
      content: NotificationContent(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: message,
        icon: 'resource://drawable/res_notification_app_icon',
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }
}

