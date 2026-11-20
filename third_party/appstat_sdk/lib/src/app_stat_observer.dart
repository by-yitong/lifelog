import 'package:flutter/widgets.dart';

import 'app_stat.dart';

class AppStatObserver extends NavigatorObserver {
  AppStatObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _report(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _report(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _report(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) _report(previousRoute);
  }

  void _report(Route<dynamic> route) {
    final path = route.settings.name ?? route.runtimeType.toString();
    AppStat.track('page_view', <String, Object?>{'path': path});
  }
}
