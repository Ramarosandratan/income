import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class MobileApp extends ConsumerWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Income',
      debugShowCheckedModeBanner: false,
      theme: buildMobileTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
