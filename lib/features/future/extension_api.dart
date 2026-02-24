/// Extension API
///
/// Provides a plugin architecture for extending Mix & Mingle
/// with custom functionality, room modes, and creator tools.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../../core/analytics/analytics_service.dart';

/// Plugin metadata
class PluginMetadata {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final PluginCategory category;
  final List<String> requiredPermissions;
  final Map<String, dynamic> config;
  final DateTime registeredAt;
  final bool isEnabled;

  const PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.category,
    this.requiredPermissions = const [],
    this.config = const {},
    required this.registeredAt,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'version': version,
    'author': author,
    'description': description,
    'category': category.name,
    'requiredPermissions': requiredPermissions,
    'config': config,
    'registeredAt': registeredAt.toIso8601String(),
    'isEnabled': isEnabled,
  };

  PluginMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    PluginCategory? category,
    List<String>? requiredPermissions,
    Map<String, dynamic>? config,
    DateTime? registeredAt,
    bool? isEnabled,
  }) {
    return PluginMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      config: config ?? this.config,
      registeredAt: registeredAt ?? this.registeredAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Plugin categories
enum PluginCategory {
  roomMode,
  creatorTool,
  moderation,
  monetization,
  analytics,
  integration,
  ui,
  utility,
}

/// Room mode definition
class RoomModeDefinition {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int minParticipants;
  final int maxParticipants;
  final bool supportsVideo;
  final bool supportsAudio;
  final bool supportsChat;
  final bool supportsScreenShare;
  final List<String> features;
  final Map<String, dynamic> defaultConfig;
  final Widget Function(BuildContext context, Map<String, dynamic> roomData)? uiBuilder;
  final Future<void> Function(String roomId)? onRoomCreated;
  final Future<void> Function(String roomId)? onRoomEnded;

  const RoomModeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.minParticipants = 1,
    this.maxParticipants = 100,
    this.supportsVideo = true,
    this.supportsAudio = true,
    this.supportsChat = true,
    this.supportsScreenShare = false,
    this.features = const [],
    this.defaultConfig = const {},
    this.uiBuilder,
    this.onRoomCreated,
    this.onRoomEnded,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'minParticipants': minParticipants,
    'maxParticipants': maxParticipants,
    'supportsVideo': supportsVideo,
    'supportsAudio': supportsAudio,
    'supportsChat': supportsChat,
    'supportsScreenShare': supportsScreenShare,
    'features': features,
    'defaultConfig': defaultConfig,
  };
}

/// Creator tool definition
class CreatorToolDefinition {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final CreatorToolType type;
  final List<String> requiredTier;
  final Map<String, dynamic> defaultSettings;
  final Widget Function(BuildContext context, String creatorId)? toolBuilder;
  final Future<Map<String, dynamic>> Function(String creatorId, Map<String, dynamic> input)? execute;

  const CreatorToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.type,
    this.requiredTier = const ['creator', 'pro'],
    this.defaultSettings = const {},
    this.toolBuilder,
    this.execute,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'type': type.name,
    'requiredTier': requiredTier,
    'defaultSettings': defaultSettings,
  };
}

/// Creator tool types
enum CreatorToolType {
  overlay,
  effects,
  analytics,
  engagement,
  monetization,
  moderation,
  scheduling,
  automation,
}

/// Plugin registration result
class PluginRegistrationResult {
  final String pluginId;
  final bool success;
  final String? error;
  final DateTime registeredAt;
  final List<String> warnings;

  const PluginRegistrationResult({
    required this.pluginId,
    required this.success,
    this.error,
    required this.registeredAt,
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
    'pluginId': pluginId,
    'success': success,
    'error': error,
    'registeredAt': registeredAt.toIso8601String(),
    'warnings': warnings,
  };
}

/// Extension API for plugin architecture
class ExtensionAPI {
  static ExtensionAPI? _instance;
  static ExtensionAPI get instance => _instance ??= ExtensionAPI._();

  ExtensionAPI._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registered plugins
  final Map<String, PluginMetadata> _plugins = {};
  final Map<String, RoomModeDefinition> _roomModes = {};
  final Map<String, CreatorToolDefinition> _creatorTools = {};

  // Stream controllers
  final _pluginController = StreamController<PluginMetadata>.broadcast();
  final _roomModeController = StreamController<RoomModeDefinition>.broadcast();
  final _creatorToolController = StreamController<CreatorToolDefinition>.broadcast();

  Stream<PluginMetadata> get pluginStream => _pluginController.stream;
  Stream<RoomModeDefinition> get roomModeStream => _roomModeController.stream;
  Stream<CreatorToolDefinition> get creatorToolStream => _creatorToolController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _pluginsCollection =>
      _firestore.collection('plugins');

  CollectionReference<Map<String, dynamic>> get _roomModesCollection =>
      _firestore.collection('room_modes');

  CollectionReference<Map<String, dynamic>> get _creatorToolsCollection =>
      _firestore.collection('creator_tools');

  // ============================================================
  // PLUGIN REGISTRATION
  // ============================================================

  /// Register a new plugin
  Future<PluginRegistrationResult> registerPlugin({
    required String id,
    required String name,
    required String version,
    required String author,
    required String description,
    required PluginCategory category,
    List<String>? requiredPermissions,
    Map<String, dynamic>? config,
  }) async {
    debugPrint('ðŸ”Œ [ExtensionAPI] Registering plugin: $name ($id)');

    final warnings = <String>[];

    try {
      // Validate plugin ID
      if (!_isValidPluginId(id)) {
        return PluginRegistrationResult(
          pluginId: id,
          success: false,
          error: 'Invalid plugin ID. Use lowercase letters, numbers, and underscores only.',
          registeredAt: DateTime.now(),
        );
      }

      // Check for duplicate
      if (_plugins.containsKey(id)) {
        final existing = _plugins[id]!;
        if (_compareVersions(version, existing.version) <= 0) {
          warnings.add('Plugin already registered with same or higher version');
        }
      }

      // Validate permissions
      final permissions = requiredPermissions ?? [];
      final invalidPermissions = permissions.where((p) => !_isValidPermission(p)).toList();
      if (invalidPermissions.isNotEmpty) {
        warnings.add('Unknown permissions: ${invalidPermissions.join(', ')}');
      }

      // Create metadata
      final metadata = PluginMetadata(
        id: id,
        name: name,
        version: version,
        author: author,
        description: description,
        category: category,
        requiredPermissions: permissions,
        config: config ?? {},
        registeredAt: DateTime.now(),
        isEnabled: true,
      );

      // Store locally
      _plugins[id] = metadata;

      // Store in Firestore
      await _pluginsCollection.doc(id).set(metadata.toMap());

      // Emit event
      _pluginController.add(metadata);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'plugin_registered', parameters: {
        'plugin_id': id,
        'category': category.name,
        'version': version,
      });

      debugPrint('âœ… [ExtensionAPI] Plugin registered: $name');

      return PluginRegistrationResult(
        pluginId: id,
        success: true,
        registeredAt: DateTime.now(),
        warnings: warnings,
      );
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to register plugin: $e');

      return PluginRegistrationResult(
        pluginId: id,
        success: false,
        error: e.toString(),
        registeredAt: DateTime.now(),
      );
    }
  }

  bool _isValidPluginId(String id) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id) && id.length <= 50;
  }

  bool _isValidPermission(String permission) {
    const validPermissions = [
      'room.read',
      'room.write',
      'user.read',
      'user.write',
      'chat.read',
      'chat.write',
      'video.access',
      'analytics.read',
      'monetization.manage',
      'moderation.enforce',
    ];
    return validPermissions.contains(permission);
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  // ============================================================
  // ROOM MODE REGISTRATION
  // ============================================================

  /// Register a new room mode
  Future<PluginRegistrationResult> registerRoomMode({
    required String id,
    required String name,
    required String description,
    String iconPath = 'assets/icons/room_default.svg',
    int minParticipants = 1,
    int maxParticipants = 100,
    bool supportsVideo = true,
    bool supportsAudio = true,
    bool supportsChat = true,
    bool supportsScreenShare = false,
    List<String>? features,
    Map<String, dynamic>? defaultConfig,
    Widget Function(BuildContext context, Map<String, dynamic> roomData)? uiBuilder,
    Future<void> Function(String roomId)? onRoomCreated,
    Future<void> Function(String roomId)? onRoomEnded,
  }) async {
    debugPrint('ðŸŽ­ [ExtensionAPI] Registering room mode: $name ($id)');

    try {
      // Validate
      if (!_isValidPluginId(id)) {
        return PluginRegistrationResult(
          pluginId: id,
          success: false,
          error: 'Invalid room mode ID',
          registeredAt: DateTime.now(),
        );
      }

      if (maxParticipants < minParticipants) {
        return PluginRegistrationResult(
          pluginId: id,
          success: false,
          error: 'maxParticipants must be >= minParticipants',
          registeredAt: DateTime.now(),
        );
      }

      // Create definition
      final mode = RoomModeDefinition(
        id: id,
        name: name,
        description: description,
        iconPath: iconPath,
        minParticipants: minParticipants,
        maxParticipants: maxParticipants,
        supportsVideo: supportsVideo,
        supportsAudio: supportsAudio,
        supportsChat: supportsChat,
        supportsScreenShare: supportsScreenShare,
        features: features ?? [],
        defaultConfig: defaultConfig ?? {},
        uiBuilder: uiBuilder,
        onRoomCreated: onRoomCreated,
        onRoomEnded: onRoomEnded,
      );

      // Store locally
      _roomModes[id] = mode;

      // Store in Firestore (without functions)
      await _roomModesCollection.doc(id).set(mode.toMap());

      // Emit event
      _roomModeController.add(mode);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'room_mode_registered', parameters: {
        'mode_id': id,
        'max_participants': maxParticipants,
        'has_video': supportsVideo,
      });

      debugPrint('âœ… [ExtensionAPI] Room mode registered: $name');

      return PluginRegistrationResult(
        pluginId: id,
        success: true,
        registeredAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to register room mode: $e');

      return PluginRegistrationResult(
        pluginId: id,
        success: false,
        error: e.toString(),
        registeredAt: DateTime.now(),
      );
    }
  }

  // ============================================================
  // CREATOR TOOL REGISTRATION
  // ============================================================

  /// Register a new creator tool
  Future<PluginRegistrationResult> registerCreatorTool({
    required String id,
    required String name,
    required String description,
    String iconPath = 'assets/icons/tool_default.svg',
    required CreatorToolType type,
    List<String>? requiredTier,
    Map<String, dynamic>? defaultSettings,
    Widget Function(BuildContext context, String creatorId)? toolBuilder,
    Future<Map<String, dynamic>> Function(String creatorId, Map<String, dynamic> input)? execute,
  }) async {
    debugPrint('ðŸ› ï¸ [ExtensionAPI] Registering creator tool: $name ($id)');

    try {
      // Validate
      if (!_isValidPluginId(id)) {
        return PluginRegistrationResult(
          pluginId: id,
          success: false,
          error: 'Invalid creator tool ID',
          registeredAt: DateTime.now(),
        );
      }

      // Create definition
      final tool = CreatorToolDefinition(
        id: id,
        name: name,
        description: description,
        iconPath: iconPath,
        type: type,
        requiredTier: requiredTier ?? ['creator', 'pro'],
        defaultSettings: defaultSettings ?? {},
        toolBuilder: toolBuilder,
        execute: execute,
      );

      // Store locally
      _creatorTools[id] = tool;

      // Store in Firestore (without functions)
      await _creatorToolsCollection.doc(id).set(tool.toMap());

      // Emit event
      _creatorToolController.add(tool);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'creator_tool_registered', parameters: {
        'tool_id': id,
        'type': type.name,
      });

      debugPrint('âœ… [ExtensionAPI] Creator tool registered: $name');

      return PluginRegistrationResult(
        pluginId: id,
        success: true,
        registeredAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to register creator tool: $e');

      return PluginRegistrationResult(
        pluginId: id,
        success: false,
        error: e.toString(),
        registeredAt: DateTime.now(),
      );
    }
  }

  // ============================================================
  // PLUGIN MANAGEMENT
  // ============================================================

  /// Get all registered plugins
  List<PluginMetadata> getPlugins({PluginCategory? category}) {
    if (category == null) return _plugins.values.toList();
    return _plugins.values.where((p) => p.category == category).toList();
  }

  /// Get plugin by ID
  PluginMetadata? getPlugin(String id) => _plugins[id];

  /// Enable/disable plugin
  Future<bool> setPluginEnabled(String pluginId, bool enabled) async {
    if (!_plugins.containsKey(pluginId)) return false;

    try {
      _plugins[pluginId] = _plugins[pluginId]!.copyWith(isEnabled: enabled);
      await _pluginsCollection.doc(pluginId).update({'isEnabled': enabled});
      _pluginController.add(_plugins[pluginId]!);
      return true;
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to update plugin status: $e');
      return false;
    }
  }

  /// Unregister plugin
  Future<bool> unregisterPlugin(String pluginId) async {
    if (!_plugins.containsKey(pluginId)) return false;

    try {
      _plugins.remove(pluginId);
      await _pluginsCollection.doc(pluginId).delete();

      debugPrint('ðŸ—‘ï¸ [ExtensionAPI] Unregistered plugin: $pluginId');
      return true;
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to unregister plugin: $e');
      return false;
    }
  }

  // ============================================================
  // ROOM MODE MANAGEMENT
  // ============================================================

  /// Get all registered room modes
  List<RoomModeDefinition> getRoomModes() => _roomModes.values.toList();

  /// Get room mode by ID
  RoomModeDefinition? getRoomMode(String id) => _roomModes[id];

  /// Get room mode UI builder
  Widget? buildRoomModeUI(String modeId, BuildContext context, Map<String, dynamic> roomData) {
    final mode = _roomModes[modeId];
    if (mode?.uiBuilder == null) return null;
    return mode!.uiBuilder!(context, roomData);
  }

  /// Trigger room mode callbacks
  Future<void> onRoomCreated(String modeId, String roomId) async {
    final mode = _roomModes[modeId];
    if (mode?.onRoomCreated != null) {
      await mode!.onRoomCreated!(roomId);
    }
  }

  Future<void> onRoomEnded(String modeId, String roomId) async {
    final mode = _roomModes[modeId];
    if (mode?.onRoomEnded != null) {
      await mode!.onRoomEnded!(roomId);
    }
  }

  // ============================================================
  // CREATOR TOOL MANAGEMENT
  // ============================================================

  /// Get all registered creator tools
  List<CreatorToolDefinition> getCreatorTools({CreatorToolType? type}) {
    if (type == null) return _creatorTools.values.toList();
    return _creatorTools.values.where((t) => t.type == type).toList();
  }

  /// Get creator tool by ID
  CreatorToolDefinition? getCreatorTool(String id) => _creatorTools[id];

  /// Build creator tool UI
  Widget? buildCreatorToolUI(String toolId, BuildContext context, String creatorId) {
    final tool = _creatorTools[toolId];
    if (tool?.toolBuilder == null) return null;
    return tool!.toolBuilder!(context, creatorId);
  }

  /// Execute creator tool
  Future<Map<String, dynamic>> executeCreatorTool(
    String toolId,
    String creatorId,
    Map<String, dynamic> input,
  ) async {
    final tool = _creatorTools[toolId];
    if (tool?.execute == null) {
      return {'success': false, 'error': 'Tool has no execute function'};
    }
    return tool!.execute!(creatorId, input);
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Load plugins from Firestore
  Future<void> loadPlugins() async {
    debugPrint('ðŸ”Œ [ExtensionAPI] Loading plugins from Firestore');

    try {
      // Load plugins
      final pluginDocs = await _pluginsCollection.get();
      for (final doc in pluginDocs.docs) {
        final data = doc.data();
        _plugins[doc.id] = PluginMetadata(
          id: data['id'] as String,
          name: data['name'] as String,
          version: data['version'] as String,
          author: data['author'] as String,
          description: data['description'] as String,
          category: PluginCategory.values.firstWhere((c) => c.name == data['category']),
          requiredPermissions: List<String>.from(data['requiredPermissions'] ?? []),
          config: (data['config'] as Map<String, dynamic>?) ?? {},
          registeredAt: DateTime.parse(data['registeredAt'] as String),
          isEnabled: data['isEnabled'] as bool? ?? true,
        );
      }

      // Load room modes
      final modeDocs = await _roomModesCollection.get();
      for (final doc in modeDocs.docs) {
        final data = doc.data();
        _roomModes[doc.id] = RoomModeDefinition(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String,
          iconPath: data['iconPath'] as String,
          minParticipants: data['minParticipants'] as int? ?? 1,
          maxParticipants: data['maxParticipants'] as int? ?? 100,
          supportsVideo: data['supportsVideo'] as bool? ?? true,
          supportsAudio: data['supportsAudio'] as bool? ?? true,
          supportsChat: data['supportsChat'] as bool? ?? true,
          supportsScreenShare: data['supportsScreenShare'] as bool? ?? false,
          features: List<String>.from(data['features'] ?? []),
          defaultConfig: (data['defaultConfig'] as Map<String, dynamic>?) ?? {},
        );
      }

      // Load creator tools
      final toolDocs = await _creatorToolsCollection.get();
      for (final doc in toolDocs.docs) {
        final data = doc.data();
        _creatorTools[doc.id] = CreatorToolDefinition(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String,
          iconPath: data['iconPath'] as String,
          type: CreatorToolType.values.firstWhere((t) => t.name == data['type']),
          requiredTier: List<String>.from(data['requiredTier'] ?? ['creator', 'pro']),
          defaultSettings: (data['defaultSettings'] as Map<String, dynamic>?) ?? {},
        );
      }

      debugPrint('âœ… [ExtensionAPI] Loaded ${_plugins.length} plugins, ${_roomModes.length} room modes, ${_creatorTools.length} creator tools');
    } catch (e) {
      debugPrint('âŒ [ExtensionAPI] Failed to load plugins: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _pluginController.close();
    _roomModeController.close();
    _creatorToolController.close();
    _plugins.clear();
    _roomModes.clear();
    _creatorTools.clear();
  }
}
