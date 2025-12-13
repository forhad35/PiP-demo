import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip_plugin/pip_configuration.dart';
import 'package:pip_plugin/pip_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pipPlugin = PipPlugin();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  // Helper to generate a consistent call ID for two users - Removed as we use Zego Invitation Service now

  @override
  Widget build(BuildContext context) {
    // Current User Info
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? "";
    final String currentUserName =
        currentUser?.displayName ?? currentUser?.email ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text("Not Logged In"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Welcome, $currentUserName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs
                          .where(
                            (doc) => doc.id != currentUserId,
                          ) // Exclude self
                          .toList();

                      if (users.isEmpty) {
                        return const Center(
                          child: Text("No other users found."),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userData =
                              users[index].data() as Map<String, dynamic>;
                          final String targetName =
                              userData['name'] ??
                              userData['email'] ??
                              "Unknown";
                          final String targetUid =
                              userData['uid'] ?? users[index].id;
                          final String targetEmail = userData['email'] ?? "";

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(20),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    targetName.isNotEmpty
                                        ? targetName[0].toUpperCase()
                                        : "?",
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(targetName),
                                    Text(targetEmail),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ZegoSendCallInvitationButton(
                                      buttonSize: const Size(40, 40),
                                      isVideoCall: true,
                                      resourceID:
                                          "zego_data", // For offline call notification
                                      invitees: [
                                        ZegoUIKitUser(
                                          id: targetUid,
                                          name: targetName,
                                        ),
                                      ],
                                    ),
                                    ZegoSendCallInvitationButton(
                                      buttonSize: const Size(40, 40),
                                      isVideoCall: false,
                                      resourceID:
                                          "zego_data", // For offline call notification
                                      invitees: [
                                        ZegoUIKitUser(
                                          id: targetUid,
                                          name: targetName,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                TextButton(
                  onPressed: () async {
                    if (await _pipPlugin.isPipSupported()) {
                      await _pipPlugin.setupPip(
                        configuration: PipConfiguration(
                          ratio: (16, 9),
                          backgroundColor: Colors.black,
                          textAlign: TextAlign.center,
                          textColor: Colors.white,
                          textSize: 16.0,
                        ),
                      );
                      _pipPlugin.updateText("PiP Text Mode");
                      _pipPlugin.startPip();
                    }
                  },
                  child: const Text("Test PiP Mode"),
                ),
              ],
            ),
    );
  }
}
