import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'auth/login_screen.dart';
import 'call/home_page.dart';
import 'constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pip Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Ensure Zego service is initialized when user is already logged in
            // We'll handle this more gracefully in a real wrapper, but for now
            // we can rely on the HomePage or specific logic.
            // Better: Return a wrapper widget that inits Zego.
            return const ZegoInitWrapper(child: HomePage());
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class ZegoInitWrapper extends StatefulWidget {
  final Widget child;
  const ZegoInitWrapper({super.key, required this.child});

  @override
  State<ZegoInitWrapper> createState() => _ZegoInitWrapperState();
}

class _ZegoInitWrapperState extends State<ZegoInitWrapper> {
  @override
  void initState() {
    super.initState();
    _initZego();
  }

  Future<void> _initZego() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: Constants.appId, // input your AppID
        appSign: Constants.appSign, // input your AppSign
        userID: user.uid,
        userName: user.displayName ?? user.email ?? "User",
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoCallType.videoCall == data.type
                    ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : ZegoCallType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          // Enable PiP
          config.topMenuBar.isVisible = true;
          config.topMenuBar.buttons = [
            ZegoCallMenuBarButtonName.minimizingButton,
            ZegoCallMenuBarButtonName.showMemberListButton,
          ];

          return config;
        },
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoAndroidNotificationConfig(
            channelID: "ZegoUIKit",
            channelName: "Call Notifications",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
