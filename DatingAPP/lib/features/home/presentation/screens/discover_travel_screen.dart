import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class DiscoverTravelScreen extends StatefulWidget {
  const DiscoverTravelScreen({super.key});

  @override
  State<DiscoverTravelScreen> createState() => _DiscoverTravelScreenState();
}

class _DiscoverTravelScreenState extends State<DiscoverTravelScreen> {
  String? _selected;
  final TextEditingController _search = TextEditingController();
  static const _destinations = [
    (
      'Bangalore',
      '2.4K people',
      'assets/images/girls-images/city_night_portrait.png',
    ),
    (
      'Mumbai',
      '3.1K people',
      'assets/images/girls-images/sunset_floral_portrait.png',
    ),
    (
      'Delhi',
      '2.0K people',
      'assets/images/girls-images/golden_hour_portrait.png',
    ),
    (
      'Hyderabad',
      '1.8K people',
      'assets/images/girls-images/cafe_coffee_portrait.png',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Travel mode',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Meet people in your next destination',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search city or country…',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _destinations
              .where(
                (d) => d.$1.toLowerCase().contains(
                  _search.text.trim().toLowerCase(),
                ),
              )
              .length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .82,
          ),
          itemBuilder: (context, index) {
            final destination = _destinations
                .where(
                  (d) => d.$1.toLowerCase().contains(
                    _search.text.trim().toLowerCase(),
                  ),
                )
                .elementAt(index);
            final selected = _selected == destination.$1;
            return InkWell(
              onTap: () => setState(() => _selected = destination.$1),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.coral : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(destination.$3, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xE9000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 8,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.$1,
                              style: AppTypography.label.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              destination.$2,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Positioned(
                          right: 10,
                          top: 10,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.coral,
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            _selected == null ? 'Choose a destination' : 'Set $_selected',
          ),
        ),
      ],
    ),
  );
}
