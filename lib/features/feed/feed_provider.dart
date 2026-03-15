// Riverpod provider for Feed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'post.dart';

final feedProvider = StateProvider<List<Post>>((ref) => []);
