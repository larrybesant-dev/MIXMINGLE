// Riverpod provider for Connections
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection.dart';

final connectionsProvider = StateProvider<List<Connection>>((ref) => []);
