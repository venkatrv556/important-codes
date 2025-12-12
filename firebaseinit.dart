import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final AudioPlayer audioPlayer = AudioPlayer();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'alert_channel',
  'Critical Alerts',
  description: 'Used for important alert notifications',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('alert_ringtone2'),
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showLocalNotification(message);
}

void playRingtone() async {
  await audioPlayer.setReleaseMode(ReleaseMode.loop);
  await audioPlayer.play(AssetSource('alert_ringtone2.mp3'));
}

void stopRingtone() {
  audioPlayer.stop();
}

void _showLocalNotification(RemoteMessage message) async {
  final title =
      message.data['title'] ?? message.notification?.title ?? 'New Alert';
  final body =
      message.data['body'] ?? message.notification?.body ?? 'Tap to respond';

  print("🛎️ showLocalNotification(): $title - $body");

  flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        sound: channel.sound,
        actions: [
          AndroidNotificationAction('ACCEPT', 'Accept'),
          AndroidNotificationAction('DECLINE', 'Decline'),
        ],
      ),
    ),
    payload: 'alert',
  );

  playRingtone();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.actionId == 'ACCEPT') {
        Fluttertoast.showToast(msg: "Accepted");

        print("✅ User tapped ACCEPT");
      } else if (response.actionId == 'DECLINE') {
        Fluttertoast.showToast(msg: "DECLINE");
        print("❌ User tapped DECLINE");
      } else {
        print("🔔 Notification tapped");
      }

      stopRingtone(); // ✅ stops ringtone on any action
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _fcmToken = 'Fetching...';

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    String? token = await messaging.getToken();
    print("📲 FCM Token: $token");

    setState(() {
      _fcmToken = token ?? 'No token available';
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      stopRingtone(); // Optional fallback
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Alert App',
      home: Scaffold(
        appBar: AppBar(title: Text('FCM Setup')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SelectableText('FCM Token:\n\n$_fcmToken'),
        ),
      ),
    );
  }
}
