import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../services/providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard & Badges"),
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
        data: (players) {
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text("No ranked players yet. Play a match to climb the ranks!"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final rank = index + 1;

              Color rankColor = Colors.grey.shade500;
              if (rank == 1) rankColor = Colors.amber;
              if (rank == 2) rankColor = Colors.blueGrey.shade400;
              if (rank == 3) rankColor = Colors.brown.shade400;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "#$rank",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Avatar with online status
                    AppAvatar(
                      photoUrl: player.photoUrl,
                      name: player.displayName,
                      radius: 20,
                      showOnlineBadge: true,
                      isOnline: player.isOnline,
                    ),
                    const SizedBox(width: 12),

                    // Player details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Level ${player.level} • ${player.xp} XP",
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // Wins & Streaks
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${player.wins} Wins",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        if (player.bestStreak > 0)
                          Text(
                            "${player.bestStreak} 🔥 Streak",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
