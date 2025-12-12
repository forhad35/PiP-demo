import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pip_plugin/pip_configuration.dart';
import 'package:pip_plugin/pip_plugin.dart';

import 'call_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pipPlugin = PipPlugin();

  // Helper to generate a consistent call ID for two users
  String _getCallID(String currentUserId, String targetUserId) {
    List<String> ids = [currentUserId, targetUserId];
    ids.sort(); // Sort to ensure consistent ID regardless of who calls
    return "${ids[0]}_${ids[1]}";
  }

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

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  targetName.isNotEmpty
                                      ? targetName[0].toUpperCase()
                                      : "?",
                                ),
                              ),
                              title: Text(targetName),
                              subtitle: Text(targetEmail),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.videocam,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      final callID = _getCallID(
                                        currentUserId,
                                        targetUid,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CallScreen(
                                            callID: callID,
                                            userID: currentUserId,
                                            userName: currentUserName,
                                            isVideoCall: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      final callID = _getCallID(
                                        currentUserId,
                                        targetUid,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CallScreen(
                                            callID: callID,
                                            userID: currentUserId,
                                            userName: currentUserName,
                                            isVideoCall: false,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
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
