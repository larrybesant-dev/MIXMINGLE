import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/presence_model.dart';

final presenceListProvider = StateProvider<List<PresenceModel>>((ref) => []);
