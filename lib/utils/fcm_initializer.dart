import 'fcm_initializer_mobile.dart'
    if (dart.library.html) 'fcm_initializer_stub.dart';

Future<void> initializeFcm() => initializeFcmImpl();
