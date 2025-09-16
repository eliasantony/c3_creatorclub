import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class _DeepLinkHandler extends StatefulWidget {
  const _DeepLinkHandler({required this.child});
  final Widget child;
  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  AppLinks? _appLinks;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _appLinks = AppLinks();
    try {
      final initial = await _appLinks!.getInitialAppLink();
      if (initial != null) {
        _handle(initial);
      }
    } catch (_) {}
    _appLinks!.uriLinkStream.listen((uri) {
      if (!mounted) return;
      _handle(uri);
    }, onError: (_) {});
  }

  void _handle(Uri uri) {
    // Expect scheme c3creatorclub://membership/(success|cancel)
    if (uri.scheme == 'c3creatorclub' && uri.host == 'membership') {
      final path = uri.path.replaceAll(RegExp('^/'), '');
      if (path == 'success') {
        if (context.mounted) context.go('/membership/success');
      } else if (path == 'cancel') {
        if (context.mounted) context.go('/membership');
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class C3App extends ConsumerWidget {
  const C3App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'c3_creatorclub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

class C3Root extends StatelessWidget {
  const C3Root({super.key});
  @override
  Widget build(BuildContext context) {
    return _DeepLinkHandler(child: const C3App());
  }
}
