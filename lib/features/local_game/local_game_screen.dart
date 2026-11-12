import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final List<String> _board = List.filled(9, '');
  final String _playerX = "X";
  final String _playerO = "O";
  bool _isXTurn = true;
  int _filledCount = 0;
  bool _gameOver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Multiplayer"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset Game",
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildNeumorphicText(),
              Expanded(
                child: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
              ),
              _buildPlayerIndicators(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Title with Neumorphic (3D) Text Effect
  Widget _buildNeumorphicText() {
    return Text(
      "Tic Tac Toe",
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Theme.of(context).colorScheme.secondary,
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          Shadow(
            color: Theme.of(context).colorScheme.inversePrimary,
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  /// Responsive Grid Layout for Web
  Widget _buildWebLayout() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: _buildGameGrid(),
      ),
    );
  }

  /// Responsive Grid Layout for Mobile
  Widget _buildMobileLayout() {
    return Center(
      child: _buildGameGrid(),
    );
  }

  /// Player Indicators (X / O turn)
  Widget _buildPlayerIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerIndicator(_playerX),
          _buildPlayerIndicator(_playerO),
        ],
      ),
    );
  }

  /// Single Player Indicator
  Widget _buildPlayerIndicator(String player) {
    bool isActive = (_isXTurn && player == _playerX) || (!_isXTurn && player == _playerO);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppTheme.neumorphicBox(context),
      child: Text(
        "Player $player",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Tic Tac Toe Grid
  Widget _buildGameGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) => _buildGridCell(index),
    );
  }

  /// Single Cell in the Grid
  Widget _buildGridCell(int index) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: AppTheme.neumorphicBox(context),
        child: Center(
          child: Text(
            _board[index],
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: _board[index] == _playerX ? Colors.redAccent : Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (_board[index].isNotEmpty || _gameOver) return;

    final symbol = _isXTurn ? _playerX : _playerO;

    setState(() {
      _board[index] = symbol;
      _isXTurn = !_isXTurn;
      _filledCount++;
    });

    _checkForWinner();
  }

  void _checkForWinner() {
    const List<List<int>> winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in winningCombinations) {
      final String a = _board[combo[0]];
      final String b = _board[combo[1]];
      final String c = _board[combo[2]];

      if (a.isNotEmpty && a == b && b == c) {
        _gameOver = true;
        _showWinnerDialog(a);
        return;
      }
    }

    if (_filledCount == 9) {
      _gameOver = true;
      _showDrawDialog();
    }
  }

  void _showWinnerDialog(String winner) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Game Over"),
        content: Text("🎉 Winner: Player $winner"),
        actions: [_buildResetButton()],
      ),
    );
  }

  void _showDrawDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Game Over"),
        content: const Text("It's a Draw!"),
        actions: [_buildResetButton()],
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () {
        _resetGame();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: AppTheme.neumorphicBox(context),
        child: const Text(
          "Play Again",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _board.fillRange(0, 9, '');
      _isXTurn = true;
      _filledCount = 0;
      _gameOver = false;
    });
  }
}
