import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/game_match.dart';
import '../../services/providers.dart';

class OnlineGameScreen extends ConsumerStatefulWidget {
  final String matchId;

  const OnlineGameScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  int _turnSecondsLeft = AppConstants.turnTimeLimitSeconds;
  Timer? _countdownTimer;
  Timer? _rematchTickerTimer;
  String _lastTurn = '';
  bool _statsRecorded = false;
  String? _floatingEmoji;
  String? _floatingMessage;
  Timer? _emojiTimer;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProfileProvider).value;
      if (user != null) {
        ref.read(presenceServiceProvider).setUserInGame(user.uid, true);
      }
    });

    _startTurnTimer();

    // 1-second ticker for turn and rematch countdowns
    _rematchTickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emojiTimer?.cancel();
    _messageTimer?.cancel();
    _rematchTickerTimer?.cancel();
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      ref.read(presenceServiceProvider).setUserInGame(user.uid, false);
    }
    super.dispose();
  }

  void _startTurnTimer() {
    _countdownTimer?.cancel();
    _turnSecondsLeft = AppConstants.turnTimeLimitSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_turnSecondsLeft > 0) {
        setState(() => _turnSecondsLeft--);
      } else {
        // Turn timeout handled
      }
    });
  }

  void _triggerFloatingEmoji(String emoji) {
    setState(() => _floatingEmoji = emoji);
    _emojiTimer?.cancel();
    _emojiTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _floatingEmoji = null);
    });
  }

  void _triggerFloatingMessage(String message) {
    setState(() => _floatingMessage = message);
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _floatingMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(activeMatchProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProfileProvider).value;

    // Listen to latest reaction or quick chat message
    ref.listen<AsyncValue<List<ChatMessage>>>(
      matchChatProvider(widget.matchId),
      (prev, next) {
        final messages = next.value ?? [];
        if (messages.isNotEmpty) {
          final last = messages.last;
          if (last.isReaction && last.emoji.isNotEmpty) {
            _triggerFloatingEmoji(last.emoji);
          } else if (!last.isReaction && last.text.isNotEmpty) {
            _triggerFloatingMessage("${last.senderName}: ${last.text}");
          }
        }
      },
    );

    return matchAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text("Error loading match: $e")),
      ),
      data: (match) {
        if (match == null) {
          return const Scaffold(
            body: Center(child: Text("Match not found or closed")),
          );
        }

        // Restart turn timer if turn changed
        if (match.currentTurn != _lastTurn) {
          _lastTurn = match.currentTurn;
          _startTurnTimer();
        }

        // Check for game over stats recording and presence updates
        if (match.status == 'finished') {
          if (!_statsRecorded && currentUser != null) {
            _statsRecorded = true;
            _recordMatchStats(match, currentUser.uid);
            ref.read(presenceServiceProvider).setUserInGame(currentUser.uid, false);
          }

          // Auto-cancel rematch if 60 seconds expired
          if (match.rematchStatus == 'pending' &&
              match.rematchExpiresAt > 0 &&
              DateTime.now().millisecondsSinceEpoch > match.rematchExpiresAt) {
            if (match.rematchRequestedBy == currentUser?.uid) {
              ref.read(matchSyncServiceProvider).cancelRematch(match.matchId);
            }
          }
        } else if (match.status == 'in_progress' && _statsRecorded) {
          // A rematch was accepted! Reset statsRecorded flag and re-enable in-game presence
          _statsRecorded = false;
          if (currentUser != null) {
            ref.read(presenceServiceProvider).setUserInGame(currentUser.uid, true);
          }
        }

        final isMyTurn = (match.currentTurn == 'X' && match.playerXId == currentUser?.uid) ||
            (match.currentTurn == 'O' && match.playerOId == currentUser?.uid);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              match.isPrivate ? "Private Match" : "Online Match",
              style: const TextStyle(fontSize: 18),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleLeave(match, currentUser?.uid),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: "Surrender",
                onPressed: match.status == 'in_progress'
                    ? () => _confirmSurrender(match, currentUser?.uid)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.handshake_outlined),
                tooltip: "Offer Draw",
                onPressed: match.status == 'in_progress'
                    ? () => _handleOfferDraw(match, currentUser?.uid)
                    : null,
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Player VS Player Header
                      _buildPlayersHeader(match, currentUser?.uid),
                      const SizedBox(height: 12),

                      // Turn indicator & Timer bar
                      _buildTurnStatus(match, isMyTurn),
                      const SizedBox(height: 8),

                      // Draw offer banner if opponent offered
                      if (match.drawOfferBy != null &&
                          match.drawOfferBy != currentUser?.uid &&
                          match.status == 'in_progress')
                        _buildDrawOfferBanner(match),

                      // Game Board
                      Expanded(
                        child: kIsWeb
                            ? AspectRatio(
                                aspectRatio: 1,
                                child: _buildBoardGrid(match, currentUser?.uid, isMyTurn),
                              )
                            : Center(
                                child: _buildBoardGrid(match, currentUser?.uid, isMyTurn),
                              ),
                      ),

                      // In-Game Emoji Reactions Bar
                      _buildReactionsBar(match, currentUser),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Animated Floating Quick Message
              if (_floatingMessage != null)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.28,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        _floatingMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

              // Animated Floating Emoji
              if (_floatingEmoji != null)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: 1.4),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: Text(
                          _floatingEmoji!,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                ),

              // Finished Dialog Overlay
              if (match.status == 'finished')
                _buildGameOverOverlay(match, currentUser?.uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersHeader(GameMatch match, String? myUid) {
    final isXTurn = match.currentTurn == 'X';

    return Row(
      children: [
        // Player X
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.neumorphicBox(
              context,
              borderRadius: 16,
              border: isXTurn ? Border.all(color: Colors.redAccent, width: 2) : null,
            ),
            child: Row(
              children: [
                AppAvatar(
                  photoUrl: match.playerXAvatar,
                  name: match.playerXName,
                  radius: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.playerXId == myUid ? "You (X)" : match.playerXName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Symbol: X",
                        style: TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "VS",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade500,
            ),
          ),
        ),

        // Player O
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.neumorphicBox(
              context,
              borderRadius: 16,
              border: !isXTurn ? Border.all(color: Colors.blueAccent, width: 2) : null,
            ),
            child: Row(
              children: [
                AppAvatar(
                  photoUrl: match.playerOAvatar,
                  name: match.playerOName,
                  radius: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.playerOId == myUid ? "You (O)" : match.playerOName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Symbol: O",
                        style: TextStyle(fontSize: 11, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurnStatus(GameMatch match, bool isMyTurn) {
    if (match.status != 'in_progress') return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.neumorphicBox(context, borderRadius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: _turnSecondsLeft <= 5 ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                isMyTurn ? "Your Turn (${_turnSecondsLeft}s)" : "Opponent's Turn (${_turnSecondsLeft}s)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isMyTurn ? Colors.green : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawOfferBanner(GameMatch match) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Icon(Icons.handshake, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Opponent offered a draw!",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(matchSyncServiceProvider).respondDraw(match, true),
            child: const Text("Accept", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => ref.read(matchSyncServiceProvider).respondDraw(match, false),
            child: const Text("Decline", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardGrid(GameMatch match, String? myUid, bool isMyTurn) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        final val = match.board[index];
        final isWinningCell = match.winningLine?.contains(index) ?? false;

        return GestureDetector(
          onTap: () {
            if (isMyTurn && val.isEmpty && match.status == 'in_progress' && myUid != null) {
              ref.read(matchSyncServiceProvider).makeMove(match, myUid, index);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: AppTheme.neumorphicBox(
              context,
              borderRadius: 14,
              customColor: isWinningCell ? Colors.green.withOpacity(0.25) : null,
              border: isWinningCell ? Border.all(color: Colors.green, width: 2) : null,
            ),
            child: Center(
              child: Text(
                val,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: val == 'X' ? Colors.redAccent : Colors.blueAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionsBar(GameMatch match, dynamic currentUser) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Quick Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _showQuickChatSheet(match, currentUser),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.deepPurple),
                    SizedBox(width: 4),
                    Text(
                      "Chat",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...AppConstants.quickReactions.map((emoji) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (currentUser != null) {
                    ref.read(chatServiceProvider).sendMatchMessage(
                          matchId: match.matchId,
                          senderId: currentUser.uid,
                          senderName: currentUser.displayName,
                          text: emoji,
                          isReaction: true,
                          emoji: emoji,
                        );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showQuickChatSheet(GameMatch match, dynamic currentUser) {
    if (currentUser == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Messages",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.quickMessages.map((msg) {
                    return ActionChip(
                      label: Text(msg),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(chatServiceProvider).sendMatchMessage(
                              matchId: match.matchId,
                              senderId: currentUser.uid,
                              senderName: currentUser.displayName,
                              text: msg,
                              isReaction: false,
                            );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverOverlay(GameMatch match, String? myUid) {
    final winnerSymbol = match.winner;
    final isDraw = winnerSymbol == 'draw';
    final mySymbol = (match.playerXId == myUid) ? 'X' : 'O';
    final iWon = (!isDraw && winnerSymbol == mySymbol);

    String title;
    IconData icon;
    Color color;

    if (isDraw) {
      title = "It's a Draw!";
      icon = Icons.handshake;
      color = Colors.amber;
    } else if (iWon) {
      title = "Victory! 🎉";
      icon = Icons.emoji_events;
      color = Colors.green;
    } else {
      title = "Defeat";
      icon = Icons.sentiment_dissatisfied;
      color = Colors.redAccent;
    }

    final isRematchPending = match.rematchStatus == 'pending';
    final isRematchRequestedByMe = match.rematchRequestedBy == myUid;
    final isRematchDeclined = match.rematchStatus == 'declined';

    int rematchSecondsLeft = 0;
    if (match.rematchExpiresAt > 0) {
      final diff = match.rematchExpiresAt - DateTime.now().millisecondsSinceEpoch;
      rematchSecondsLeft = diff > 0 ? (diff / 1000).ceil() : 0;
    }

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.neumorphicBox(context, borderRadius: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDraw ? "Both players played well" : "Winner: Player $winnerSymbol",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Rematch Section
              if (isRematchPending && isRematchRequestedByMe) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Rematch requested...",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Waiting for opponent (${rematchSecondsLeft}s left)",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text("Cancel Request", style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          ref.read(matchSyncServiceProvider).cancelRematch(match.matchId);
                        },
                      ),
                    ],
                  ),
                ),
              ] else if (isRematchPending && !isRematchRequestedByMe && rematchSecondsLeft > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Opponent wants a rematch!",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Auto-cancels in ${rematchSecondsLeft}s",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text("Accept"),
                            onPressed: () {
                              ref.read(matchSyncServiceProvider).respondRematch(match, true);
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text("Decline"),
                            onPressed: () {
                              ref.read(matchSyncServiceProvider).respondRematch(match, false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (isRematchDeclined) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Rematch was declined.",
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    if (myUid != null) {
                      ref.read(matchSyncServiceProvider).requestRematch(match, myUid);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: AppTheme.neumorphicBox(
                      context,
                      borderRadius: 12,
                      customColor: Colors.deepPurple.shade600,
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Request Rematch (60s)",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (myUid != null) {
                    ref.read(presenceServiceProvider).setUserInGame(myUid, false);
                  }
                  context.go('/');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: AppTheme.neumorphicBox(context, borderRadius: 12),
                  alignment: Alignment.center,
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recordMatchStats(GameMatch match, String myUid) {
    final mySymbol = (match.playerXId == myUid) ? 'X' : 'O';
    final isDraw = match.winner == 'draw';
    final isWin = (!isDraw && match.winner == mySymbol);

    ref.read(profileServiceProvider).recordGameResult(
          myUid,
          isWin: isWin,
          isDraw: isDraw,
        );
  }

  void _confirmSurrender(GameMatch match, String? myUid) {
    if (myUid == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Surrender Match?"),
        content: const Text("Surrendering will award victory to your opponent."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(matchSyncServiceProvider).surrender(match, myUid);
            },
            child: const Text("Surrender", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleOfferDraw(GameMatch match, String? myUid) {
    if (myUid == null) return;
    ref.read(matchSyncServiceProvider).offerDraw(match.matchId, myUid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draw offer sent to opponent")),
    );
  }

  void _handleLeave(GameMatch match, String? myUid) {
    if (match.status == 'in_progress' && myUid != null) {
      _confirmSurrender(match, myUid);
    } else {
      context.go('/');
    }
  }
}
