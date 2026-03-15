import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/video_engine_service.dart';

final agoraEngineProvider = Provider<VideoEngineService>((ref) {
  return VideoEngineService();
});
