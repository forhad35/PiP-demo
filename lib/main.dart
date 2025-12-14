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
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier(
    Duration.zero,
  );

  @override
  void initState() {
    super.initState();
    _initZego();
  }

  @override
  void dispose() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    _durationNotifier.dispose();
    super.dispose();
  }

  Future<void> _initZego() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: Constants.appId, // input your AppID
        appSign: Constants.appSign, // input your AppSign
        userID: user.uid,
        userName: user.displayName ?? user.email ?? "User",
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoCallInvitationType.videoCall == data.type
                    ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : ZegoCallInvitationType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          // Enable PiP
          config.topMenuBar.isVisible = true;
          config.topMenuBar.buttons = [
            ZegoCallMenuBarButtonName.minimizingButton,
            ZegoCallMenuBarButtonName.showMemberListButton,
          ];

          /// Listen to duration updates
          config.duration.onDurationUpdate = (Duration duration) {
            _durationNotifier.value = duration;
          };

          return config;
        },
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            callChannel: ZegoCallAndroidNotificationChannelConfig(
              channelID: "ZegoUIKit",
              channelName: "Call Notifications",
              sound:
                  "call_ringtone", // Ensure this resource exists or use default
              vibrate: true,
            ),
          ),
          iOSNotificationConfig: ZegoCallIOSNotificationConfig(
            systemCallingIconName: 'CallKitIcon',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,

          /// Zego Minimized Call Bar
          ValueListenableBuilder<bool>(
            valueListenable:
                ZegoUIKitPrebuiltCallController().minimize.isMinimizingNotifier,
            builder: (context, isMinimizing, _) {
              if (!isMinimizing) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ZegoUIKitPrebuiltCallController().minimize.restore(context);
                  },
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green, // Or your app's primary color
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.call, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          "Call in progress",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Call Duration
                        ValueListenableBuilder<Duration>(
                          valueListenable: _durationNotifier,
                          builder: (context, duration, _) {
                            final String formattedDuration =
                                "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
                            return Text(
                              formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
