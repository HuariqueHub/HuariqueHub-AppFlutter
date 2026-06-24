import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.tryAutoLogin();
  runApp(
    ChangeNotifierProvider.value(
      value: auth,
      child: HuariqueHubApp(auth: auth),
    ),
  );
}

class HuariqueHubApp extends StatefulWidget {

  final AuthProvider auth;
  const HuariqueHubApp({super.key, required this.auth});

  @override
  State<HuariqueHubApp> createState() => _HuariqueHubAppState();
}

class _HuariqueHubAppState extends State<HuariqueHubApp> {

  late final _router = AppRouter.router(widget.auth);

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      title: 'HuariqueHub',
      theme: appTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
