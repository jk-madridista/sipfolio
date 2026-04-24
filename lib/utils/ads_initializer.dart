import 'ads_initializer_mobile.dart'
    if (dart.library.html) 'ads_initializer_stub.dart';

Future<void> initializeAds() => initializeAdsImpl();
