import 'package:go_router/go_router.dart';

import '../stitch_prototype_viewer.dart';

class StitchPrototypeRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const StitchPrototypeViewer(),
      ),
    ],
  );
}
