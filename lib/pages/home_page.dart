import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mid_app/models/user_profile.dart';
import 'package:mid_app/pages/chat_page.dart';
import 'package:mid_app/pages/profile_page.dart';
import 'package:mid_app/services/alert_service.dart';
import 'package:mid_app/services/auth_service.dart';
import 'package:mid_app/services/database_service.dart';
import 'package:mid_app/services/navigation_service.dart';
import 'package:mid_app/widgets/chat_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [
          IconButton(
            onPressed: () async {
              bool result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                  text: "Successfully logged out",
                  icon: Icons.check,
                );
                _navigationService.pushReplacementNamed("/login");
              }
            },
            color: Colors.red,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigationService.push(
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: _chatsList(),
      ),
    );
  }

  Widget _chatsList() {
    return StreamBuilder(
      stream: _databaseService.getUserProfiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Unable to load data."),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserProfile user = users[index].data();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ChatTile(
                  userProfile: user,
                  onTap: () async {
                    final chatExists = await _databaseService.checkChatExists(
                      _authService.user!.uid,
                      user.uid!,
                    );
                    if (!chatExists) {
                      await _databaseService.createNewChat(
                        _authService.user!.uid,
                        user.uid!,
                      );
                    }
                    _navigationService.push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ChatPage(
                            chatUser: user,
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
