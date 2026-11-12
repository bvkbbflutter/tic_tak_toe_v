import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/models/challenge_model.dart';
import '../../services/providers.dart';
import '../friends/friends_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOnlinePresence();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlinePresence();
    } else if (state == AppLifecycleState.paused) {
      final user = ref.read(currentUserProfileProvider).value;
      if (user != null) {
        ref.read(presenceServiceProvider).setUserOffline(user.uid);
      }
    }
  }

  void _updateOnlinePresence() {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      ref.read(presenceServiceProvider).setUserOnline(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomingChallenges = ref.watch(incomingChallengesProvider).value ?? [];
    final activeChallenge = incomingChallenges.isNotEmpty ? incomingChallenges.first : null;
    final currentUser = ref.watch(currentUserProfileProvider).value;

    final List<Widget> pages = [
      _buildHomeTab(),
      _buildPlayTab(),
      const FriendsScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex],
          if (activeChallenge != null && currentUser != null)
            _buildChallengeBanner(activeChallenge, currentUser),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: AppTheme.neumorphicBox(context, borderRadius: 0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(1, Icons.sports_esports_rounded, "Play"),
                _buildNavItem(2, Icons.people_alt_rounded, "Friends"),
                _buildNavItem(3, Icons.emoji_events_rounded, "Ranks"),
                _buildNavItem(4, Icons.account_circle_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeBanner(ChallengeModel challenge, dynamic currentUser) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppAvatar(
                    photoUrl: challenge.fromAvatar,
                    name: challenge.fromName,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "⚔️ ${challenge.fromName}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          "Challenged you to a game! (${challenge.secondsRemaining}s left)",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Decline"),
                    onPressed: () {
                      ref.read(challengeServiceProvider).respondChallenge(
                            challenge: challenge,
                            responder: currentUser,
                            accept: false,
                          );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Accept"),
                    onPressed: () async {
                      final ok = await ref.read(challengeServiceProvider).respondChallenge(
                            challenge: challenge,
                            responder: currentUser,
                            accept: true,
                          );
                      if (ok && mounted) {
                        context.push('/game/${challenge.matchId}');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected ? AppTheme.neumorphicBox(context, borderRadius: 16) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepPurple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Match History",
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player Header Card
                if (profile != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.neumorphicBox(context, borderRadius: 18),
                    child: Row(
                      children: [
                        AppAvatar(
                          photoUrl: profile.photoUrl,
                          name: profile.displayName,
                          radius: 28,
                          showOnlineBadge: true,
                          isOnline: profile.isOnline,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                "ID: ${profile.playerId} • Level ${profile.level}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${profile.wins} Wins",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Quick Play Hero Card
                GestureDetector(
                  onTap: () => context.push('/matchmaking'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.neumorphicBox(context, borderRadius: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.deepPurple, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quick Match",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Instant matchmaking with online players worldwide",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Local Multiplayer Card (Preserved!)
                GestureDetector(
                  onTap: () => context.push('/game/local'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.neumorphicBox(context, borderRadius: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.devices, color: Colors.blue, size: 30),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Local 2-Player Game",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Play locally on this device without internet connection",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Match History & Replays Card
                GestureDetector(
                  onTap: () => context.push('/history'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.neumorphicBox(context, borderRadius: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.slow_motion_video, color: Colors.teal, size: 30),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Match History & Replays",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Review past matches with move-by-move timeline slider",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Modes"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildModeTile(
                  title: "Online Quick Match",
                  subtitle: "Match against a random player online",
                  icon: Icons.public,
                  color: Colors.deepPurple,
                  onTap: () => context.push('/matchmaking'),
                ),
                const SizedBox(height: 16),
                _buildModeTile(
                  title: "Create Private Room",
                  subtitle: "Generate a QR code & 6-digit code for your friend",
                  icon: Icons.meeting_room,
                  color: Colors.indigo,
                  onTap: _showCreateRoomDialog,
                ),
                const SizedBox(height: 16),
                _buildModeTile(
                  title: "Scan QR Code to Join",
                  subtitle: "Point camera at friend's screen to join instantly",
                  icon: Icons.qr_code_scanner,
                  color: Colors.pinkAccent,
                  onTap: () => context.push('/qr-scanner'),
                ),
                const SizedBox(height: 16),
                _buildModeTile(
                  title: "Join with Room Code",
                  subtitle: "Enter a 6-digit code provided by your friend",
                  icon: Icons.key,
                  color: Colors.teal,
                  onTap: _showJoinRoomDialog,
                ),
                const SizedBox(height: 16),
                _buildModeTile(
                  title: "Local Multiplayer (Pass & Play)",
                  subtitle: "Two players on the same screen (Offline supported)",
                  icon: Icons.phone_android,
                  color: Colors.blueAccent,
                  onTap: () => context.push('/game/local'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.neumorphicBox(context, borderRadius: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;

    final match = await ref.read(matchmakingServiceProvider).createPrivateRoom(profile);
    if (!mounted) return;

    final roomCode = match.roomCode ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Private Room Created", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Have your friend scan this QR code to join immediately:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: roomCode,
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text("Or enter this 6-digit code:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/game/online/${match.matchId}');
            },
            child: const Text("Enter Room"),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinRoomDialog() async {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Join Private Room"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Scan Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/qr-scanner');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: AppTheme.neumorphicBox(context, borderRadius: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.deepPurple, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Scan QR Code with Camera",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("OR ENTER CODE", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "Enter 6-digit room code",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) return;

              final profile = ref.read(currentUserProfileProvider).value;
              if (profile == null) return;

              final match = await ref
                  .read(matchmakingServiceProvider)
                  .joinPrivateRoom(code, profile);

              if (mounted) {
                Navigator.pop(context);
                if (match != null) {
                  context.go('/game/online/${match.matchId}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Room not found or already full")),
                  );
                }
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}
