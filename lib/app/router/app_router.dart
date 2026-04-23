import 'package:go_router/go_router.dart';
import '../../stitch_ui/stitch_viewer.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StitchViewer(),
      ),
    ],
  );
}
