import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_toe_v/utils/neumorphic_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _board = List.filled(9, '');
  final String _playerX = "X";
  final String _playerO = "O";
  bool _isXTurn = true;
  int _filledCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildNeumorphicText(),
              Expanded(
                child: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
              ),
              // const SizedBox(height: 20),
              _buildPlayerIndicators(),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Title with Neumorphic (3D) Text Effect
  Widget _buildNeumorphicText() {
    return Text(
      "Tik Tak Toe",
      style: TextStyle(
        fontSize: 50,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: neumorphicDecoration(context),
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
        decoration: neumorphicDecoration(context),
        child: Center(
          child: Text(
            _board[index],
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _board[index] == _playerX ? Colors.redAccent : Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (_board[index].isNotEmpty) return;

    setState(() {
      _board[index] = _isXTurn ? _playerX : _playerO;
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
        _showWinnerDialog(a);
        return;
      }
    }

    if (_filledCount == 9) {
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
        content: Text("🎉 Winner: $winner"),
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
        decoration: neumorphicDecoration(context),
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
    });
  }
}



// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final List<String> _board = List.filled(9, '');
//   final String _playerX = "X";
//   final String _playerO = "O";
//   bool _isXTurn = true;
//   int _filledCount = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 1200),
//           padding: const EdgeInsets.all(16),
//           child: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
//         ),
//       ),
//     );
//   }

//   Widget _buildWebLayout() {
//     return Row(
//       children: [
//         const Spacer(),
//         Expanded(flex: 3, child: _buildGameGrid()),
//         const Spacer(),
//       ],
//     );
//   }

//   Widget _buildMobileLayout() {
//     return Column(
//       children: [
//         const SizedBox(height: 40),
//         _buildNeumorphicText(),
//         // const SizedBox(height: 30),

//         // Center the grid with flexible height
//         Expanded(
//           child: Center(
//             child: AspectRatio(
//               aspectRatio: 1, // 1:1 square grid
//               child: _buildGameGrid(),
//             ),
//           ),
//         ),

//         // Player indicators at the bottom
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildPlayerIndicator(_playerX),
//               _buildPlayerIndicator(_playerO),
//             ],
//           ),
//         ),
//       ],
//     );
//   }


//   Widget _buildNeumorphicText() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final textColor = isDark ? Colors.white : Colors.black;
//     final shadowColorDark = isDark ? Colors.black.withOpacity(0.7) : Colors.grey.shade400;
//     final shadowColorLight = isDark ? Colors.white.withOpacity(0.2) : Colors.white;

//     return Text(
//       "Tik Tak Toe",
//       style: TextStyle(
//         fontSize: 50,
//         fontWeight: FontWeight.bold,
//         color: textColor,
//         letterSpacing: 1.2,
//         shadows: [
//           Shadow(
//             color: Theme.of(context).colorScheme.secondary,
//             offset: const Offset(4, 4),
//             blurRadius: 6,
//           ),
//           Shadow(
//             color: Theme.of(context).colorScheme.inversePrimary,
//             offset: Offset(-4, -4),
//             blurRadius: 6,
//           ),
//         ],
//       ),
//     );
//   }



//   Widget _buildPlayerIndicator(String player) {
//     bool isActive = (_isXTurn && player == _playerX) || (!_isXTurn && player == _playerO);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: neumorphicDecoration(context),
//       child: Text(
//         "Player $player",
//         style: TextStyle(
//           color: isActive ? Colors.green : Colors.grey,
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//     );
//   }


//   Widget _buildGameGrid() {
//     return GridView.builder(
//       itemCount: 9,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//       ),
//       itemBuilder: (context, index) => _buildGridCell(index),
//     );
//   }

//   Widget _buildGridCell(int index) {
//     return GestureDetector(
//       onTap: () => _handleTap(index),
//       child: Container(
//         margin: const EdgeInsets.all(8),
//         decoration: neumorphicDecoration(context),
//         child: Center(
//           child: Text(
//             _board[index],
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: _board[index] == _playerX ? Colors.redAccent : Colors.blue,
//             ),
//           ),
//         ),
//       ),
//     );
//   }


//   void _handleTap(int index) {
//     if (_board[index].isNotEmpty) return;

//     setState(() {
//       _board[index] = _isXTurn ? _playerX : _playerO;
//       _isXTurn = !_isXTurn;
//       _filledCount++;
//     });

//     _checkForWinner();
//   }

//   void _checkForWinner() {
//     const List<List<int>> winningCombinations = [
//       [0, 1, 2],
//       [3, 4, 5],
//       [6, 7, 8], // Rows
//       [0, 3, 6],
//       [1, 4, 7],
//       [2, 5, 8], // Columns
//       [0, 4, 8],
//       [2, 4, 6], // Diagonals
//     ];

//     for (var combo in winningCombinations) {
//       final String a = _board[combo[0]];
//       final String b = _board[combo[1]];
//       final String c = _board[combo[2]];

//       if (a.isNotEmpty && a == b && b == c) {
//         _showWinnerDialog(a);
//         return;
//       }
//     }

//     if (_filledCount == 9) {
//       _showDrawDialog();
//     }
//   }

//   void _showWinnerDialog(String winner) {
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         title: const Text("Game Over"),
//         content: Text("🎉 Winner: $winner"),
//         actions: [_buildResetButton()],
//       ),
//     );
//   }

//   void _showDrawDialog() {
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         title: const Text("Game Over"),
//         content: const Text("It's a Draw!"),
//         actions: [_buildResetButton()],
//       ),
//     );
//   }

//   Widget _buildResetButton() {
//     return GestureDetector(
//       onTap: () {
//         _resetGame();
//         Navigator.pop(context);
//       },
//       child: Container(
//         padding: EdgeInsets.all(10),
//         decoration: neumorphicDecoration(context),
//         child: const Text("Play Again"),
//       ),
//     );
//   }

//   void _resetGame() {
//     setState(() {
//       _board.fillRange(0, 9, '');
//       _isXTurn = true;
//       _filledCount = 0;
//     });
//   }
// }