import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/user_profile.dart';
import '../../services/challenge_service.dart';
import '../../services/providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  List<PastOpponent> _pastOpponents = [];
  bool _isSearching = false;
  bool _isLoadingOpponents = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPastOpponents();
    });
  }

  Future<void> _loadPastOpponents() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      final list = await ref.read(challengeServiceProvider).getPastOpponents(user.uid);
      if (mounted) {
        setState(() {
          _pastOpponents = list;
          _isLoadingOpponents = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingOpponents = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await ref.read(profileServiceProvider).searchPlayers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends & Opponents"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _handleSearch,
                          decoration: const InputDecoration(
                            hintText: "Search by Player ID (e.g. TTT-...) or Username",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search Results
                if (_isSearching)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (_searchResults.isNotEmpty) ...[
                  const Text("Search Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._searchResults.map((player) => _buildPlayerCard(player, currentUser)),
                  const Divider(height: 32),
                ],

                // Past Opponents Section
                if (_isLoadingOpponents)
                  const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                else if (_pastOpponents.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Past Opponents",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "${_pastOpponents.length} players",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._pastOpponents.map((opp) => _buildPastOpponentCard(opp, currentUser)),
                  const Divider(height: 32),
                ],

                // Active Players / Online Friends
                const Text(
                  "Active Players Worldwide",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                leaderboardAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text("Error: $e"),
                  data: (players) {
                    final others = players.where((p) => p.uid != currentUser?.uid).toList();
                    if (others.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No other active players online right now."),
                      );
                    }
                    return Column(
                      children: others.map((p) => _buildPlayerCard(p, currentUser)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastOpponentCard(PastOpponent opp, UserProfile? currentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
      child: Row(
        children: [
          AppAvatar(
            photoUrl: opp.photoUrl,
            name: opp.displayName,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opp.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Games: ${opp.gamesPlayed} • Won: ${opp.winsAgainst} • Lost: ${opp.lossesAgainst}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Challenge Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text("Challenge", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              if (currentUser != null) {
                _initiateChallenge(
                  context,
                  currentUser: currentUser,
                  targetUid: opp.uid,
                  targetName: opp.displayName,
                  targetAvatar: opp.photoUrl,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(UserProfile player, UserProfile? currentUser) {
    final isOnline = player.computedIsOnline;
    final isInGame = player.computedIsInGame;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
      child: Row(
        children: [
          AppAvatar(
            photoUrl: player.photoUrl,
            name: player.displayName,
            radius: 22,
            showOnlineBadge: true,
            isOnline: isOnline,
            isInGame: isInGame,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "@${player.username} • ID: ${player.playerId}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  isInGame
                      ? "In Match"
                      : (isOnline ? "Online" : "Offline"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInGame
                        ? Colors.amber
                        : (isOnline ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // Challenge Button
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.deepPurple, size: 22),
            tooltip: "Challenge Player",
            onPressed: () {
              if (currentUser != null) {
                _initiateChallenge(
                  context,
                  currentUser: currentUser,
                  targetUid: player.uid,
                  targetName: player.displayName,
                  targetAvatar: player.photoUrl,
                  targetPlayerId: player.playerId,
                );
              }
            },
          ),

          // Message Button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
            tooltip: "Direct Chat",
            onPressed: () {
              if (currentUser != null) {
                final convId = ref
                    .read(chatServiceProvider)
                    .getConversationId(currentUser.uid, player.uid);
                context.push('/chat/$convId?name=${Uri.encodeComponent(player.displayName)}');
              }
            },
          ),
        ],
      ),
    );
  }

  void _initiateChallenge(
    BuildContext context, {
    required UserProfile currentUser,
    required String targetUid,
    required String targetName,
    required String targetAvatar,
    String targetPlayerId = '',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ChallengeWaitingDialog(
        currentUser: currentUser,
        targetUid: targetUid,
        targetName: targetName,
        targetAvatar: targetAvatar,
        targetPlayerId: targetPlayerId,
      ),
    );
  }
}

class _ChallengeWaitingDialog extends ConsumerStatefulWidget {
  final UserProfile currentUser;
  final String targetUid;
  final String targetName;
  final String targetAvatar;
  final String targetPlayerId;

  const _ChallengeWaitingDialog({
    required this.currentUser,
    required this.targetUid,
    required this.targetName,
    required this.targetAvatar,
    required this.targetPlayerId,
  });

  @override
  ConsumerState<_ChallengeWaitingDialog> createState() => _ChallengeWaitingDialogState();
}

class _ChallengeWaitingDialogState extends ConsumerState<_ChallengeWaitingDialog> {
  ChallengeModel? _challenge;
  StreamSubscription? _sub;
  Timer? _countdownTimer;
  int _secondsLeft = 60;
  String _statusMessage = "Sending challenge...";
  bool _isDeclined = false;

  @override
  void initState() {
    super.initState();
    _startChallenge();
  }

  Future<void> _startChallenge() async {
    final targetProfile = UserProfile(
      uid: widget.targetUid,
      playerId: widget.targetPlayerId,
      username: widget.targetName,
      displayName: widget.targetName,
      photoUrl: widget.targetAvatar,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final challenge = await ref.read(challengeServiceProvider).sendChallenge(
          fromUser: widget.currentUser,
          toUser: targetProfile,
        );

    if (!mounted) return;

    if (challenge == null) {
      setState(() => _statusMessage = "Failed to send challenge. Please try again.");
      return;
    }

    setState(() {
      _challenge = challenge;
      _statusMessage = "Waiting for ${widget.targetName} to accept...";
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() => _statusMessage = "Challenge expired. No response received.");
      }
    });

    _sub = ref
        .read(challengeServiceProvider)
        .streamChallenge(challenge.challengeId)
        .listen((updated) {
      if (updated == null || !mounted) return;
      if (updated.status == 'accepted') {
        _countdownTimer?.cancel();
        Navigator.of(context, rootNavigator: true).pop();
        context.push('/game/${updated.matchId}');
      } else if (updated.status == 'declined') {
        _countdownTimer?.cancel();
        setState(() {
          _isDeclined = true;
          _statusMessage = "${widget.targetName} declined your challenge.";
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _handleCancel() {
    if (_challenge != null) {
      ref.read(challengeServiceProvider).cancelChallenge(_challenge!.challengeId, _challenge!.matchId);
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: Colors.deepPurple),
          SizedBox(width: 8),
          Text("Challenging Opponent", style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            photoUrl: widget.targetAvatar,
            name: widget.targetName,
            radius: 30,
          ),
          const SizedBox(height: 12),
          Text(
            widget.targetName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _isDeclined ? Colors.red : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isDeclined && _secondsLeft > 0) ...[
            Text(
              "${_secondsLeft}s",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleCancel,
          child: Text(_isDeclined || _secondsLeft == 0 ? "Close" : "Cancel"),
        ),
      ],
    );
  }
}
