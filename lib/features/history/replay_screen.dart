import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_match.dart';
import '../../services/local_cache_service.dart';

class ReplayScreen extends StatefulWidget {
  final String matchId;

  const ReplayScreen({super.key, required this.matchId});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  GameMatch? _match;
  int _currentMoveIndex = 0; // 0 = empty board, 1..N = moves applied
  bool _isPlaying = false;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _loadMatch() {
    final cached = LocalCacheService.getCachedMatch(widget.matchId);
    if (cached != null) {
      setState(() {
        _match = cached;
        _currentMoveIndex = cached.moves.length;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_match == null || _match!.moves.isEmpty) return;
      if (_currentMoveIndex >= _match!.moves.length) {
        _currentMoveIndex = 0;
      }
      setState(() => _isPlaying = true);
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
        if (!mounted) return;
        if (_currentMoveIndex < _match!.moves.length) {
          setState(() => _currentMoveIndex++);
        } else {
          _playbackTimer?.cancel();
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  List<String> _reconstructBoard(int moveCount) {
    final board = List.filled(9, '');
    if (_match == null) return board;

    for (int i = 0; i < moveCount && i < _match!.moves.length; i++) {
      final move = _match!.moves[i];
      if (move.index >= 0 && move.index < 9) {
        board[move.index] = move.symbol;
      }
    }
    return board;
  }

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Game Replay")),
        body: const Center(child: Text("Match data not found")),
      );
    }

    final totalMoves = _match!.moves.length;
    final board = _reconstructBoard(_currentMoveIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Move-by-Move Replay"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Match info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_match!.playerXName} (X)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Result: ${_match!.winner == 'draw' ? 'Draw' : 'Winner: ${_match!.winner}'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    Text(
                      "${_match!.playerOName} (O)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Replay Board
              Expanded(
                child: kIsWeb
                    ? AspectRatio(
                        aspectRatio: 1,
                        child: _buildBoardGrid(board),
                      )
                    : Center(
                        child: _buildBoardGrid(board),
                      ),
              ),

              const SizedBox(height: 12),

              // Move timeline slider
              Text(
                "Move $_currentMoveIndex of $totalMoves",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Slider(
                value: _currentMoveIndex.toDouble(),
                min: 0,
                max: totalMoves > 0 ? totalMoves.toDouble() : 1,
                divisions: totalMoves > 0 ? totalMoves : 1,
                activeColor: Colors.deepPurple,
                onChanged: totalMoves > 0
                    ? (val) {
                        setState(() {
                          _currentMoveIndex = val.toInt();
                        });
                      }
                    : null,
              ),

              // Controls: Step Prev, Play/Pause, Step Next, Restart
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay),
                    tooltip: "Restart",
                    onPressed: () => setState(() => _currentMoveIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    tooltip: "Previous Move",
                    onPressed: _currentMoveIndex > 0
                        ? () => setState(() => _currentMoveIndex--)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: AppTheme.neumorphicBox(context, borderRadius: 26),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    tooltip: "Next Move",
                    onPressed: _currentMoveIndex < totalMoves
                        ? () => setState(() => _currentMoveIndex++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardGrid(List<String> board) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        final val = board[index];
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
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
        );
      },
    );
  }
}
