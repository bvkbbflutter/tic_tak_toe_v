import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_match.dart';
import '../../services/local_cache_service.dart';

class MatchHistoryScreen extends ConsumerStatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  ConsumerState<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends ConsumerState<MatchHistoryScreen> {
  String _filter = 'All'; // 'All', 'Wins', 'Losses', 'Draws'

  @override
  Widget build(BuildContext context) {
    final matches = LocalCacheService.getCachedMatches();

    final filtered = matches.where((m) {
      if (_filter == 'All') return true;
      if (_filter == 'Wins') return m.winner == 'X';
      if (_filter == 'Losses') return m.winner == 'O';
      if (_filter == 'Draws') return m.winner == 'draw';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match History"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Wins', 'Losses', 'Draws'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: AppTheme.neumorphicBox(
                        context,
                        borderRadius: 20,
                        border: isSelected
                            ? Border.all(color: Colors.deepPurple, width: 2)
                            : null,
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.deepPurple : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No matches found",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final match = filtered[index];
                      return _buildMatchCard(match);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(GameMatch match) {
    final dateStr = DateFormat.yMMMd().add_jm().format(match.createdAt);
    final isDraw = match.winner == 'draw';
    final resultText = isDraw ? "DRAW" : "WINNER: ${match.winner}";
    final resultColor = isDraw
        ? Colors.amber
        : (match.winner == 'X' ? Colors.green : Colors.blueAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: resultColor),
            ),
            child: Text(
              resultText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: resultColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${match.playerXName} vs ${match.playerOName}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$dateStr • ${match.moves.length} moves",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 30),
            tooltip: "Watch Replay",
            onPressed: () => context.push('/game/replay/${match.matchId}'),
          ),
        ],
      ),
    );
  }
}
