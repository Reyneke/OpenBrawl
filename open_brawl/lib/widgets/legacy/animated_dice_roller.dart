import 'package:flutter/material.dart';
import 'package:open_brawl/widgets/legacy/dice_roller.dart';

/**
 * // Einfacher Aufruf
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const DiceRollerScreen(),
  ),
);

// Mit voreingestelltem Pool
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const DiceRollerScreen(initialPool: 12),
  ),
);
 * 
 */

class AnimatedDiceRoller extends StatefulWidget {
  final DiceRoller diceRoller;
  final int pool;
  final VoidCallback onRollComplete;

  const AnimatedDiceRoller({
    super.key,
    required this.diceRoller,
    required this.pool,
    required this.onRollComplete,
  });

  @override
  State<AnimatedDiceRoller> createState() => _AnimatedDiceRollerState();
}

class _AnimatedDiceRollerState extends State<AnimatedDiceRoller>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  List<int> _currentRolls = [];
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 360).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishRoll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startRoll() {
    setState(() {
      _isRolling = true;
      _currentRolls = List.generate(widget.pool, (_) => 1);
    });
    _controller.forward(from: 0);

    // Simuliere zwischendurch zufällige Würfel
    int frameCount = 0;
    void updateRolls() {
      if (frameCount < 10 && _isRolling) {
        setState(() {
          _currentRolls = List.generate(
            widget.pool,
            (_) => (_currentRolls.first + 1) % 6 + 1,
          );
        });
        frameCount++;
        Future.delayed(const Duration(milliseconds: 50), updateRolls);
      }
    }

    updateRolls();
  }

  void _finishRoll() {
    final result = widget.diceRoller.rollDice(pool: widget.pool);
    setState(() {
      _currentRolls = result.rolls;
      _isRolling = false;
    });
    widget.onRollComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 3.14159 / 180,
          child: child,
        );
      },
      child: Wrap(
        spacing: 8,
        children: _currentRolls.map((roll) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: roll >= 5
                    ? Colors.green
                    : roll == 1
                    ? Colors.red
                    : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                roll.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: roll >= 5
                      ? Colors.green
                      : roll == 1
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
