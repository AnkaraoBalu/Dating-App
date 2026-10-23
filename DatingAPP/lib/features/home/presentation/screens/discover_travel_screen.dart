import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class DiscoverTravelScreen extends StatefulWidget {
  const DiscoverTravelScreen({super.key, this.currentCity});

  /// The travel city in use, if any. When set, the screen offers a way back
  /// to the member's own location.
  final String? currentCity;

  /// Returned instead of a city when the member turns travel mode off.
  static const myLocation = '';

  @override
  State<DiscoverTravelScreen> createState() => _DiscoverTravelScreenState();
}

class _DiscoverTravelScreenState extends State<DiscoverTravelScreen> {
  late String? _selected = widget.currentCity;
  // Keep in sync with travelCities in the backend's discovery-location.ts
  // (backend/test/discovery-location.test.cjs checks this). Each city's photo
  // is assets/images/travel/<city>.png; until it is added the card shows a
  // styled placeholder.
  static const _destinations = [
    ('Bangalore', 'Karnataka', 'assets/images/travel/bangalore.png'),
    ('Mumbai', 'Maharashtra', 'assets/images/travel/mumbai.png'),
    ('Delhi', 'National Capital', 'assets/images/travel/delhi.png'),
    ('Hyderabad', 'Telangana', 'assets/images/travel/hyderabad.png'),
    ('Chennai', 'Tamil Nadu', 'assets/images/travel/chennai.png'),
    ('Kolkata', 'West Bengal', 'assets/images/travel/kolkata.png'),
    ('Pune', 'Maharashtra', 'assets/images/travel/pune.png'),
    ('Ahmedabad', 'Gujarat', 'assets/images/travel/ahmedabad.png'),
    ('Gurugram', 'Haryana', 'assets/images/travel/gurugram.png'),
    ('Noida', 'Uttar Pradesh', 'assets/images/travel/noida.png'),
    ('Jaipur', 'Rajasthan', 'assets/images/travel/jaipur.png'),
    ('Goa', 'Goa', 'assets/images/travel/goa.png'),
    ('Chandigarh', 'Chandigarh', 'assets/images/travel/chandigarh.png'),
    ('Kochi', 'Kerala', 'assets/images/travel/kochi.png'),
    ('Lucknow', 'Uttar Pradesh', 'assets/images/travel/lucknow.png'),
    (
      'Visakhapatnam',
      'Andhra Pradesh',
      'assets/images/travel/visakhapatnam.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Travel mode',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      // Title and buttons stay put; only the city grid scrolls.
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Meet people in your next destination',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  itemCount: _destinations.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .82,
                  ),
                  itemBuilder: (context, index) {
                    final destination = _destinations[index];
                    final selected = _selected == destination.$1;
                    // Ink paints on the nearest Material; giving each
                    // card its own keeps borders clipped while scrolling.
                    return Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => setState(() => _selected = destination.$1),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.coral
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  destination.$3,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _CityFallback(),
                                ),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xE9000000),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 8,
                                  bottom: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (widget.currentCity != null) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, DiscoverTravelScreen.myLocation),
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Back to my location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderStrong),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
        ),
      ),
    );
  }
}

class _CityFallback extends StatelessWidget {
  const _CityFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.forest, AppColors.coral],
      ),
    ),
    child: Align(
      alignment: Alignment(0, -0.35),
      child: Icon(Icons.location_city_rounded, color: Colors.white54, size: 44),
    ),
  );
}
