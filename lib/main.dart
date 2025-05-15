import 'package:flutter/material.dart';
import 'package:gmw_protocol/core/di/service_locator.dart';
import 'package:gmw_protocol/core/theme/theme.dart';
import 'package:gmw_protocol/data/theme_datasource.dart';
import 'package:gmw_protocol/domain/controller/protocol_controller.dart';
import 'package:gmw_protocol/domain/controller/theme_controller.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';
import 'package:gmw_protocol/presentation/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final themeDatasource = ThemeDatasourceImpl(preferences: preferences);
  final themeController = ThemeController(themeDatasource: themeDatasource);

  await themeController.load();
  kServiceLocator['themeController'] = themeController;
  kServiceLocator['protocolController'] = ProtocolController(
    aliceSession: GMWSession(
      me: ParticipantId('alice'),
      peer: ParticipantId('bob'),
      sharer: SecretSharingImpl(),
      otProvider: ObliviousTransferBucketImpl(ParticipantId('alice')),
    ),
    bobSession: GMWSession(
      me: ParticipantId('bob'),
      peer: ParticipantId('alice'),
      sharer: SecretSharingImpl(),
      otProvider: ObliviousTransferBucketImpl(ParticipantId('bob')),
    ),
  );

  runApp(const GMWApp());
}

class GMWApp extends StatelessWidget {
  const GMWApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = kServiceLocator['themeController']! as ThemeController;
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GMW Protocol App',
          theme: themeController.isDark ? darkMode : lightMode,
          routes: {
            '/home': (BuildContext context) => const HomePage(),
            // '/home': (BuildContext context) => const HomePage(),
          },
          home: const HomePage(),
        );
      },
    );
  }
}
