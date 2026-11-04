import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwaliko/core/config.dart';
import 'package:mwaliko/data/demo_store.dart';

void main() {
  group('Kununua salio ndani ya app', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('kumezimwa kwenye app ya iPhone (App Store 3.1.3(f))', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(AppConfig.canBuyCredits, isFalse);
    });

    test('kunaruhusiwa kwenye Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppConfig.canBuyCredits, isTrue);
    });
  });

  test('kufuta akaunti ya demo kunarudisha data ya mwanzo na kumtoa mteja', () {
    final demo = DemoStore.instance;
    final events = demo.events.length;
    final guests = demo.guests.length;
    demo.signIn(email: 'asha@mfano.co.tz');
    demo.credits = 3;
    demo.events.clear();
    demo.payments.clear();

    demo.reset();

    expect(demo.signedInUser, isNull);
    expect(demo.credits, 24);
    expect(demo.events.length, events);
    expect(demo.guests.length, guests);
    expect(demo.payments, isNotEmpty);
  });

  test('links za kisheria zinatoka kwenye web app', () {
    expect(AppConfig.privacyUrl, endsWith('/privacy.html'));
    expect(AppConfig.termsUrl, endsWith('/terms.html'));
    expect(AppConfig.privacyUrl, startsWith('https://'));
  });
}
