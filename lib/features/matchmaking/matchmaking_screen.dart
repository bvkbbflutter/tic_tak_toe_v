import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_match.dart';
import '../../services/providers.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  StreamSubscription<GameMatch?>? _matchSub;
  String? _activeMatchId;
  String _statusText = "Checking for online players...";
  String _subtitleText = "Searching for an opponent...";
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _noPlayersFound = false;
  static const int _searchTimeoutSeconds = 15;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuickMatch();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    _matchSub?.cancel();
    _matchSub = null;
    super.dispose();
  }

  Future<void> _startQuickMatch() async {
    setState(() {
      _noPlayersFound = false;
      _secondsElapsed = 0;
      _statusText = "Checking for online players...";
      _subtitleText = "Searching for an opponent...";
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);

      if (_secondsElapsed >= _searchTimeoutSeconds && !_noPlayersFound) {
        _handleTimeout();
      }
    });

    final userProfile = ref.read(currentUserProfileProvider).value;
    if (userProfile == null) return;

    try {
      final matchmakingService = ref.read(matchmakingServiceProvider);
      final matchId = await matchmakingService.findQuickMatch(userProfile);

      if (!mounted) return;

      if (matchId == null) {
        // No other registered players exist in the app
        _timer?.cancel();
        setState(() {
          _noPlayersFound = true;
          _statusText = "No players found";
          _subtitleText = "You are currently the only registered player in the game. Invite a friend or play locally!";
        });
        return;
      }

      _activeMatchId = matchId;
      setState(() {
        _statusText = "Searching for an opponent...";
        _subtitleText = "Waiting for a player to join...";
      });

      // Listen safely for opponent joining
      final matchSyncService = ref.read(matchSyncServiceProvider);
      _matchSub?.cancel();
      _matchSub = matchSyncService.streamMatch(matchId).listen((match) {
        if (!mounted || match == null) return;

        if (match.status == 'in_progress') {
          _timer?.cancel();
          setState(() {
            _statusText = "Opponent found! Starting game...";
            _subtitleText = "Connecting to match...";
          });

          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              context.go('/game/online/${match.matchId}');
            }
          });
        }
      }, onError: (e) {
        debugPrint('Match listener safely handled: $e');
      });
    } catch (e) {
      if (mounted) {
        _timer?.cancel();
        setState(() {
          _noPlayersFound = true;
          _statusText = "No players found";
          _subtitleText = "Unable to connect to matchmaking. Please try again.";
        });
      }
    }
  }

  Future<void> _handleTimeout() async {
    _timer?.cancel();
    final idToCancel = _activeMatchId;
    _activeMatchId = null;

    // Cancel listener first to avoid permission-denied event on document deletion
    await _matchSub?.cancel();
    _matchSub = null;

    if (idToCancel != null) {
      try {
        await ref.read(matchmakingServiceProvider).cancelMatchmaking(idToCancel);
      } catch (e) {
        debugPrint('Error cancelling timed out match: $e');
      }
    }

    if (mounted) {
      setState(() {
        _noPlayersFound = true;
        _statusText = "No players found";
        _subtitleText = "No opponents are currently online or available in queue. You can retry or challenge a friend!";
      });
    }
  }

  Future<void> _handleCancel() async {
    _timer?.cancel();
    final idToCancel = _activeMatchId;
    _activeMatchId = null;

    // Always cancel subscription before deleting to prevent permission error
    await _matchSub?.cancel();
    _matchSub = null;

    if (idToCancel != null) {
      try {
        await ref.read(matchmakingServiceProvider).cancelMatchmaking(idToCancel);
      } catch (e) {
        debugPrint('Safe cancel error: $e');
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _createPrivateRoom() async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;

    try {
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
    } catch (e) {
      debugPrint('Error creating private room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matchmaking"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _noPlayersFound ? _buildNoPlayersFoundView() : _buildSearchingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Radar
        RotationTransition(
          turns: _animController,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.05),
                  Colors.deepPurpleAccent.withOpacity(0.85),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: AppTheme.neumorphicBox(context, borderRadius: 55),
                child: const Icon(
                  Icons.radar,
                  size: 48,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Status Text
        Text(
          _statusText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          _subtitleText,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),

        // Elapsed / Remaining Time
        Text(
          "Searching: ${_secondsElapsed}s (Timeout in ${_searchTimeoutSeconds - _secondsElapsed}s)",
          style: TextStyle(
            fontSize: 13,
            color: Colors.deepPurple.shade300,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 48),

        // Cancel Button
        GestureDetector(
          onTap: _handleCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
            child: const Text(
              "Cancel Search",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlayersFoundView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // No Players Icon
        Container(
          width: 90,
          height: 90,
          decoration: AppTheme.neumorphicBox(context, borderRadius: 45),
          child: Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          _statusText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Subtitle description
        Text(
          _subtitleText,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Action 1: Create Private Room (Play with Friend)
        GestureDetector(
          onTap: _createPrivateRoom,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Create Room & Show QR Code",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action 2: Scan Friend's QR Code
        GestureDetector(
          onTap: () => context.push('/qr-scanner'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 20, color: Colors.pinkAccent),
                SizedBox(width: 8),
                Text(
                  "Scan Friend's QR Code to Join",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action 2: Play Local Game
        GestureDetector(
          onTap: () => context.push('/game/local'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices, size: 20, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  "Play Local Pass & Play",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action 3: Retry Search
        GestureDetector(
          onTap: _startQuickMatch,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Retry Search",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Back to Dashboard
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            "Back to Home",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
