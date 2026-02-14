/// Platform Adapter
///
/// Provides adaptive layouts, input bridges, and device capability detection
/// for multi-platform support.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Device form factor
enum DeviceFormFactor {
  phone,
  tablet,
  desktop,
  tv,
  vr,
  wearable,
  unknown,
}

/// Input modality
enum InputModality {
  touch,
  mouse,
  keyboard,
  gamepad,
  remote,
  voice,
  gesture,
  eyeTracking,
}

/// Device capabilities
class DeviceCapabilities {
  final DeviceFormFactor formFactor;
  final Set<InputModality> inputModalities;
  final bool hasCamera;
  final bool hasMicrophone;
  final bool hasSpeaker;
  final bool hasHaptics;
  final bool hasGPS;
  final bool hasAccelerometer;
  final bool hasGyroscope;
  final bool hasNFC;
  final bool hasBluetooth;
  final bool hasAR;
  final bool hasVR;
  final int screenWidth;
  final int screenHeight;
  final double pixelRatio;
  final bool isHighRefreshRate;
  final bool supportsHDR;
  final String platform;
  final String osVersion;

  const DeviceCapabilities({
    required this.formFactor,
    required this.inputModalities,
    this.hasCamera = false,
    this.hasMicrophone = false,
    this.hasSpeaker = false,
    this.hasHaptics = false,
    this.hasGPS = false,
    this.hasAccelerometer = false,
    this.hasGyroscope = false,
    this.hasNFC = false,
    this.hasBluetooth = false,
    this.hasAR = false,
    this.hasVR = false,
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.pixelRatio = 1.0,
    this.isHighRefreshRate = false,
    this.supportsHDR = false,
    this.platform = 'unknown',
    this.osVersion = 'unknown',
  });

  bool get isPhone => formFactor == DeviceFormFactor.phone;
  bool get isTablet => formFactor == DeviceFormFactor.tablet;
  bool get isDesktop => formFactor == DeviceFormFactor.desktop;
  bool get isTV => formFactor == DeviceFormFactor.tv;
  bool get isVR => formFactor == DeviceFormFactor.vr;
  bool get isWearable => formFactor == DeviceFormFactor.wearable;

  bool get supportsTouch => inputModalities.contains(InputModality.touch);
  bool get supportsMouse => inputModalities.contains(InputModality.mouse);
  bool get supportsKeyboard => inputModalities.contains(InputModality.keyboard);
  bool get supportsGamepad => inputModalities.contains(InputModality.gamepad);
  bool get supportsVoice => inputModalities.contains(InputModality.voice);
}

/// Adaptive layout breakpoints
class AdaptiveBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
  static const double large = 1600;

  static LayoutSize getLayoutSize(double width) {
    if (width < compact) return LayoutSize.compact;
    if (width < medium) return LayoutSize.medium;
    if (width < expanded) return LayoutSize.expanded;
    if (width < large) return LayoutSize.large;
    return LayoutSize.extraLarge;
  }
}

/// Layout size category
enum LayoutSize {
  compact,
  medium,
  expanded,
  large,
  extraLarge,
}

/// Platform adapter singleton
class PlatformAdapter {
  static PlatformAdapter? _instance;
  static PlatformAdapter get instance => _instance ??= PlatformAdapter._();

  PlatformAdapter._();

  DeviceCapabilities? _capabilities;

  /// Get current device capabilities
  DeviceCapabilities get capabilities {
    _capabilities ??= _detectCapabilities();
    return _capabilities!;
  }

  // ============================================================
  // DEVICE CAPABILITY DETECTION
  // ============================================================

  /// Detect device capabilities
  DeviceCapabilities _detectCapabilities() {
    final formFactor = _detectFormFactor();
    final inputModalities = _detectInputModalities(formFactor);

    return DeviceCapabilities(
      formFactor: formFactor,
      inputModalities: inputModalities,
      hasCamera: _detectCamera(),
      hasMicrophone: _detectMicrophone(),
      hasSpeaker: true,
      hasHaptics: _detectHaptics(),
      hasGPS: _detectGPS(),
      hasAccelerometer: _detectAccelerometer(),
      hasGyroscope: _detectGyroscope(),
      hasNFC: _detectNFC(),
      hasBluetooth: _detectBluetooth(),
      hasAR: _detectAR(),
      hasVR: _detectVR(),
      platform: _detectPlatform(),
      osVersion: _detectOSVersion(),
    );
  }

  DeviceFormFactor _detectFormFactor() {
    if (kIsWeb) {
      // Web detection based on user agent and screen size
      return DeviceFormFactor.desktop;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // TODO: Check screen size to differentiate phone/tablet
        return DeviceFormFactor.phone;
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return DeviceFormFactor.desktop;
      }
    } catch (_) {
      // Platform not available
    }

    return DeviceFormFactor.unknown;
  }

  Set<InputModality> _detectInputModalities(DeviceFormFactor formFactor) {
    final modalities = <InputModality>{};

    switch (formFactor) {
      case DeviceFormFactor.phone:
      case DeviceFormFactor.tablet:
        modalities.addAll([InputModality.touch, InputModality.voice]);
        break;
      case DeviceFormFactor.desktop:
        modalities.addAll([
          InputModality.mouse,
          InputModality.keyboard,
          InputModality.touch,
        ]);
        break;
      case DeviceFormFactor.tv:
        modalities.addAll([
          InputModality.remote,
          InputModality.voice,
          InputModality.gamepad,
        ]);
        break;
      case DeviceFormFactor.vr:
        modalities.addAll([
          InputModality.gesture,
          InputModality.voice,
          InputModality.eyeTracking,
        ]);
        break;
      case DeviceFormFactor.wearable:
        modalities.addAll([InputModality.touch, InputModality.voice]);
        break;
      case DeviceFormFactor.unknown:
        modalities.add(InputModality.touch);
        break;
    }

    return modalities;
  }

  bool _detectCamera() {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectMicrophone() {
    return true; // Most devices have microphones
  }

  bool _detectHaptics() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectGPS() {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectAccelerometer() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectGyroscope() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectNFC() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectBluetooth() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows;
    } catch (_) {
      return false;
    }
  }

  bool _detectAR() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool _detectVR() {
    // VR requires specific device type
    return false;
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform not available
    }
    return 'unknown';
  }

  String _detectOSVersion() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Refresh capabilities detection
  void refreshCapabilities() {
    _capabilities = _detectCapabilities();
    debugPrint('🔄 [PlatformAdapter] Capabilities refreshed');
  }

  // ============================================================
  // ADAPTIVE LAYOUTS
  // ============================================================

  /// Get adaptive layout for current context
  AdaptiveLayout adaptiveLayouts(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final layoutSize = AdaptiveBreakpoints.getLayoutSize(size.width);

    return AdaptiveLayout(
      layoutSize: layoutSize,
      width: size.width,
      height: size.height,
      orientation: MediaQuery.of(context).orientation,
      formFactor: capabilities.formFactor,
      padding: _getAdaptivePadding(layoutSize),
      columns: _getAdaptiveColumns(layoutSize),
      navigationMode: _getNavigationMode(layoutSize, capabilities.formFactor),
    );
  }

  EdgeInsets _getAdaptivePadding(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return const EdgeInsets.all(16);
      case LayoutSize.medium:
        return const EdgeInsets.all(24);
      case LayoutSize.expanded:
        return const EdgeInsets.all(32);
      case LayoutSize.large:
      case LayoutSize.extraLarge:
        return const EdgeInsets.all(48);
    }
  }

  int _getAdaptiveColumns(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return 4;
      case LayoutSize.medium:
        return 8;
      case LayoutSize.expanded:
        return 12;
      case LayoutSize.large:
      case LayoutSize.extraLarge:
        return 12;
    }
  }

  NavigationMode _getNavigationMode(LayoutSize size, DeviceFormFactor formFactor) {
    if (formFactor == DeviceFormFactor.tv) {
      return NavigationMode.rail;
    }

    switch (size) {
      case LayoutSize.compact:
        return NavigationMode.bottomBar;
      case LayoutSize.medium:
        return NavigationMode.rail;
      case LayoutSize.expanded:
      case LayoutSize.large:
      case LayoutSize.extraLarge:
        return NavigationMode.drawer;
    }
  }

  // ============================================================
  // INPUT BRIDGES
  // ============================================================

  /// Get input bridge for current platform
  InputBridge inputBridges() {
    return InputBridge(
      capabilities: capabilities,
      keyboardShortcuts: _getKeyboardShortcuts(),
      gamepadMapping: _getGamepadMapping(),
      gestureMapping: _getGestureMapping(),
    );
  }

  Map<LogicalKeySet, String> _getKeyboardShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.space): 'toggle_mute',
      LogicalKeySet(LogicalKeyboardKey.keyV): 'toggle_video',
      LogicalKeySet(LogicalKeyboardKey.keyC): 'open_chat',
      LogicalKeySet(LogicalKeyboardKey.keyP): 'open_participants',
      LogicalKeySet(LogicalKeyboardKey.escape): 'exit_fullscreen',
      LogicalKeySet(LogicalKeyboardKey.keyF): 'toggle_fullscreen',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM): 'toggle_mute',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): 'toggle_video',
    };
  }

  Map<String, String> _getGamepadMapping() {
    return {
      'a_button': 'select',
      'b_button': 'back',
      'x_button': 'toggle_mute',
      'y_button': 'toggle_video',
      'left_bumper': 'previous_room',
      'right_bumper': 'next_room',
      'start': 'open_menu',
      'dpad_up': 'navigate_up',
      'dpad_down': 'navigate_down',
      'dpad_left': 'navigate_left',
      'dpad_right': 'navigate_right',
    };
  }

  Map<String, String> _getGestureMapping() {
    return {
      'swipe_left': 'next_page',
      'swipe_right': 'previous_page',
      'swipe_up': 'open_participants',
      'swipe_down': 'close_overlay',
      'pinch_in': 'zoom_out',
      'pinch_out': 'zoom_in',
      'double_tap': 'toggle_fullscreen',
      'long_press': 'open_context_menu',
    };
  }

  // ============================================================
  // PLATFORM-SPECIFIC UI
  // ============================================================

  /// Get platform-specific styling
  PlatformStyle getPlatformStyle() {
    final formFactor = capabilities.formFactor;

    switch (formFactor) {
      case DeviceFormFactor.tv:
        return const PlatformStyle(
          fontSize: 24,
          iconSize: 48,
          buttonHeight: 64,
          focusColor: Colors.blue,
          useFocusHighlight: true,
          animationSpeed: 1.5,
        );
      case DeviceFormFactor.vr:
        return const PlatformStyle(
          fontSize: 32,
          iconSize: 64,
          buttonHeight: 80,
          focusColor: Colors.cyan,
          useFocusHighlight: true,
          animationSpeed: 0.8,
        );
      case DeviceFormFactor.wearable:
        return const PlatformStyle(
          fontSize: 12,
          iconSize: 20,
          buttonHeight: 36,
          focusColor: Colors.green,
          useFocusHighlight: false,
          animationSpeed: 1.0,
        );
      case DeviceFormFactor.desktop:
        return const PlatformStyle(
          fontSize: 14,
          iconSize: 24,
          buttonHeight: 40,
          focusColor: Colors.blue,
          useFocusHighlight: true,
          animationSpeed: 1.0,
        );
      default:
        return const PlatformStyle(
          fontSize: 16,
          iconSize: 24,
          buttonHeight: 48,
          focusColor: Colors.purple,
          useFocusHighlight: false,
          animationSpeed: 1.0,
        );
    }
  }
}

/// Adaptive layout configuration
class AdaptiveLayout {
  final LayoutSize layoutSize;
  final double width;
  final double height;
  final Orientation orientation;
  final DeviceFormFactor formFactor;
  final EdgeInsets padding;
  final int columns;
  final NavigationMode navigationMode;

  const AdaptiveLayout({
    required this.layoutSize,
    required this.width,
    required this.height,
    required this.orientation,
    required this.formFactor,
    required this.padding,
    required this.columns,
    required this.navigationMode,
  });

  bool get isCompact => layoutSize == LayoutSize.compact;
  bool get isMedium => layoutSize == LayoutSize.medium;
  bool get isExpanded =>
      layoutSize == LayoutSize.expanded ||
      layoutSize == LayoutSize.large ||
      layoutSize == LayoutSize.extraLarge;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;
}

/// Navigation mode
enum NavigationMode {
  bottomBar,
  rail,
  drawer,
}

/// Input bridge configuration
class InputBridge {
  final DeviceCapabilities capabilities;
  final Map<LogicalKeySet, String> keyboardShortcuts;
  final Map<String, String> gamepadMapping;
  final Map<String, String> gestureMapping;

  const InputBridge({
    required this.capabilities,
    required this.keyboardShortcuts,
    required this.gamepadMapping,
    required this.gestureMapping,
  });

  /// Handle keyboard shortcut
  String? handleKeyboardShortcut(LogicalKeySet keySet) {
    return keyboardShortcuts[keySet];
  }

  /// Handle gamepad button
  String? handleGamepadButton(String button) {
    return gamepadMapping[button];
  }

  /// Handle gesture
  String? handleGesture(String gesture) {
    return gestureMapping[gesture];
  }
}

/// Platform-specific styling
class PlatformStyle {
  final double fontSize;
  final double iconSize;
  final double buttonHeight;
  final Color focusColor;
  final bool useFocusHighlight;
  final double animationSpeed;

  const PlatformStyle({
    required this.fontSize,
    required this.iconSize,
    required this.buttonHeight,
    required this.focusColor,
    required this.useFocusHighlight,
    required this.animationSpeed,
  });
}

/// Adaptive layout builder widget
class AdaptiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AdaptiveLayout layout) builder;

  const AdaptiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final layout = PlatformAdapter.instance.adaptiveLayouts(context);
    return builder(context, layout);
  }
}

/// Focus-aware button for TV/Desktop
class FocusAwareButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool autofocus;

  const FocusAwareButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.autofocus = false,
  });

  @override
  State<FocusAwareButton> createState() => _FocusAwareButtonState();
}

class _FocusAwareButtonState extends State<FocusAwareButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final style = PlatformAdapter.instance.getPlatformStyle();

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: (200 / style.animationSpeed).round()),
          decoration: BoxDecoration(
            border: _isFocused && style.useFocusHighlight
                ? Border.all(color: style.focusColor, width: 3)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
