import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/presence_model.dart';

final presenceListProvider = StateProvider<List<PresenceModel>>((ref) => []);
