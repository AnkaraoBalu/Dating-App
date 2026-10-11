import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../data/welcome_slides.dart';
import '../widgets/welcome_carousel_controls.dart';
import '../widgets/welcome_slide_page.dart';
import '../../../login/presentation/navigation/login_routes.dart';
import '../../../login/presentation/screens/login_screen.dart';

class WelcomeCarouselScreen extends StatefulWidget {
  const WelcomeCarouselScreen({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  State<WelcomeCarouselScreen> createState() => _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends State<WelcomeCarouselScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: AppMotion.slow,
        curve: AppMotion.curve,
      );
    }
  }

  void _next() {
    if (_index < WelcomeSlides.all.length - 1) {
      _goTo(_index + 1);
      return;
    }
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      LoginRoutes.push<void>(context, const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.light,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => _index > 0
                          ? _goTo(_index - 1)
                          : Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_index + 1} / ${WelcomeSlides.all.length}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: WelcomeSlides.all.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: _controller,
                    child: WelcomeSlidePage(slide: WelcomeSlides.all[index]),
                    builder: (context, child) {
                      if (MediaQuery.disableAnimationsOf(context)) {
                        return child!;
                      }
                      final page =
                          _controller.hasClients &&
                              _controller.position.hasContentDimensions
                          ? _controller.page ?? _index.toDouble()
                          : _index.toDouble();
                      final distance = (page - index).abs().clamp(0.0, 1.0);
                      return Opacity(
                        opacity: 1 - distance * 0.45,
                        child: Transform.scale(
                          scale: 1 - distance * 0.025,
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
              WelcomeCarouselControls(
                index: _index,
                count: WelcomeSlides.all.length,
                onSelected: _goTo,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
