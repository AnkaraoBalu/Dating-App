import 'package:dating_app/features/home/presentation/widgets/home_person_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefetch and displayed photo share the same network provider', () {
    const url = 'https://example.test/photo.jpg';
    final provider = HomePersonPhoto.providerFor(url);
    expect(provider, isA<NetworkImage>());
    final image = HomePersonPhoto.imageFor(url) as Image;
    expect(image.image, provider);
  });

  test('bundled demo photos and assets prefetch locally', () {
    final demo = HomePersonPhoto.providerFor(
      'https://i.pravatar.cc/?img=22',
      personName: 'Maya',
    );
    expect(demo, isA<AssetImage>());
    expect(
      HomePersonPhoto.providerFor('assets/images/photo.png'),
      isA<AssetImage>(),
    );
    expect(HomePersonPhoto.providerFor(''), isNull);
    expect(HomePersonPhoto.imageFor(''), isA<ColoredBox>());
  });
}
