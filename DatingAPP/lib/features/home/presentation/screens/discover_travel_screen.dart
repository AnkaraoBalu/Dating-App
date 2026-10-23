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
  final TextEditingController _search = TextEditingController();
  // Keep in sync with travelCities in the backend's discovery-location.ts
  // (backend/test/discovery-location.test.cjs checks this). A city without a
  // photo in assets/images/travel/ shows a styled card instead.
  static const _destinations = <(String, String, String?)>[
    ('Bangalore', 'Karnataka', 'assets/images/travel/bangalore.png'),
    ('Mumbai', 'Maharashtra', 'assets/images/travel/mumbai.png'),
    ('Delhi', 'National Capital', 'assets/images/travel/delhi.png'),
    ('Hyderabad', 'Telangana', 'assets/images/travel/hyderabad.png'),
    ('Chennai', 'Tamil Nadu', null),
    ('Kolkata', 'West Bengal', null),
    ('Pune', 'Maharashtra', null),
    ('Ahmedabad', 'Gujarat', null),
    ('Gurugram', 'Haryana', null),
    ('Noida', 'Uttar Pradesh', null),
    ('Jaipur', 'Rajasthan', null),
    ('Goa', 'Goa', null),
    ('Chandigarh', 'Chandigarh', null),
    ('Kochi', 'Kerala', null),
    ('Lucknow', 'Uttar Pradesh', null),
    ('Indore', 'Madhya Pradesh', null),
    ('Visakhapatnam', 'Andhra Pradesh', null),
    ('Vijayawada', 'Andhra Pradesh', null),
    ('Warangal', 'Telangana', null),
    ('Coimbatore', 'Tamil Nadu', null),
    ('Mysuru', 'Karnataka', null),
    ('Thiruvananthapuram', 'Kerala', null),
    ('Puducherry', 'Puducherry', null),
    ('Bhubaneswar', 'Odisha', null),
    ('Nagpur', 'Maharashtra', null),
    ('Surat', 'Gujarat', null),
    ('Udaipur', 'Rajasthan', null),
    ('Varanasi', 'Uttar Pradesh', null),
    ('Rishikesh', 'Uttarakhand', null),
    ('Shimla', 'Himachal Pradesh', null),
    ('Manali', 'Himachal Pradesh', null),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final destinations = _destinations
        .where(
          (d) =>
              d.$1.toLowerCase().contains(query) ||
              d.$2.toLowerCase().contains(query),
        )
        .toList();
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
              hintText: 'Search city or state…',
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
          if (destinations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No cities match "${_search.text.trim()}" yet.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: destinations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) {
              final destination = destinations[index];
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
                        if (destination.$3 case final image?)
                          Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _CityFallback(),
                          )
                        else
                          const _CityFallback(),
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
