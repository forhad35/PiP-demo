import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../constants.dart';

class CallScreen extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: Constants.appId,
      appSign: Constants.appSign,
      userID: userID,
      userName: userName,
      callID: callID,
      config: isVideoCall 
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() 
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        ..topMenuBar.isVisible = true
        ..topMenuBar.buttons = [
          ZegoCallMenuBarButtonName.minimizingButton,
          ZegoCallMenuBarButtonName.showMemberListButton,
        ],
    );
  }
}
