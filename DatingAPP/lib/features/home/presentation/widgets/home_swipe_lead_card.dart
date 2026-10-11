part of 'home_discover_sections.dart';

// Draggable lead card: swipe right to like, left to pass.
class _SwipeLeadCard extends StatefulWidget {
  const _SwipeLeadCard({
    super.key,
    required this.person,
    required this.onMore,
    required this.onPass,
    required this.onLike,
    required this.onTap,
    required this.liked,
  });

  final HomePerson person;
  final VoidCallback onMore;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final bool liked;

  @override
  State<_SwipeLeadCard> createState() => _SwipeLeadCardState();
}

class _SwipeLeadCardState extends State<_SwipeLeadCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  bool _settling = false;
  double _cardWidth = 360;
  Tween<double> _path = Tween(begin: 0, end: 0);
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          if (!mounted) return;
          setState(
            () => _setPosition(
              _path.transform(Curves.easeOutCubic.transform(_motion.value)),
            ),
          );
        });
  }

  void _setPosition(double x) {
    _dragX = x;
    // Translation and rotation follow the same shallow upward arc.
    final progress = (x.abs() / _cardWidth).clamp(0.0, 1.5);
    _dragY = -22 * progress * progress;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _updateDrag(double delta) {
    if (_settling) return;
    setState(() {
      _setPosition((_dragX + delta).clamp(-_cardWidth * 1.5, _cardWidth * 1.5));
    });
  }

  void _endDrag(double velocity) {
    if (_settling) return;
    final flung =
        _dragX.abs() > 24 &&
        velocity.abs() > 700 &&
        velocity.sign == _dragX.sign;
    if (_dragX.abs() < _cardWidth * .25 && !flung) {
      _returnToCenter();
    } else {
      _dismiss(_dragX > 0);
    }
  }

  Future<bool> _animateTo(double x) async {
    _settling = true;
    _path = Tween(begin: _dragX, end: x);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _setPosition(x));
      return true;
    }
    try {
      await _motion.forward(from: 0).orCancel;
      return mounted;
    } on TickerCanceled {
      return false;
    }
  }

  Future<void> _returnToCenter() async {
    // A button tap also cancels the parent's drag recognizer. Keep that tap
    // available when the card has not actually moved.
    if (_settling || _dragX.abs() < .01) return;
    if (await _animateTo(0)) setState(() => _settling = false);
  }

  Future<void> _dismiss(bool like) async {
    if (_settling) return;
    HapticFeedback.lightImpact();
    if (!await _animateTo((like ? 1 : -1) * (_cardWidth * 1.5 + 40))) {
      return;
    }
    if (like) {
      widget.onLike();
    } else {
      widget.onPass();
    }
    if (mounted) {
      setState(() {
        _setPosition(0);
        _settling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cardWidth = constraints.maxWidth;
        return Transform.translate(
          offset: Offset(_dragX, _dragY),
          child: Transform.rotate(
            alignment: Alignment.bottomCenter,
            angle: (_dragX / _cardWidth) * .16,
            child: HomeDiscoverSections._leadCardBody(
              person: widget.person,
              onMore: () {
                if (!_settling) widget.onMore();
              },
              onPass: () => _dismiss(false),
              onLike: () => _dismiss(true),
              onTap: () {
                if (!_settling) widget.onTap();
              },
              liked: widget.liked,
              dragX: _dragX,
              onDragUpdate: _updateDrag,
              onDragEnd: _endDrag,
              onDragCancel: _returnToCenter,
            ),
          ),
        );
      },
    );
  }
}
