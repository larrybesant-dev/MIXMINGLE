b06c07aff68f73e951a35ecdf36\flutter_windows.dll.rule;C:\MixVy\build\windows\x64\CMakeFiles\f81a5d5e2e4bab80d86029262111bb31\flutter_assemble.rule;C:\MixVy\windows\flutter\CMakeLists.txt' exited with code 1. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
C:\MixVy\windows\flutter\ephemeral\.plugin_symlinks\iris_method_channel\src\iris_event.cc(212,56): warning C4244: '=': conversion from 'intptr_t' to 'int', possible loss of data [C:\MixVy\build\windows\x64\plugins\iris_method_channel\shared\iris_method_channel.vcxproj]
Building Windows application...                                    90.9s
Error: Build process failed.
PS C:\MixVy> 
 *  History restored 

PS C:\MixVy> lib/stitch_ui/stitch_viewer.dart
lib/stitch_ui/stitch_viewer.dart: The term 'lib/stitch_ui/stitch_viewer.dart' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS C:\MixVy> New-Item -Path lib\stitch_ui\stitch_viewer.dart -ItemType File -Force

    Directory: C:\MixVy\lib\stitch_ui

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---           4/22/2026  8:33 PM              0 stitch_viewer.dart

PS C:\MixVy> notepad lib\stitch_ui\stitch_viewer.dart                             
PS C:\MixVy> flutter clean         
Deleting build...                                                  204ms
Deleting .dart_tool...                                              38ms
Deleting ephemeral...                                                1ms
Deleting Generated.xcconfig...                                       0ms
Deleting flutter_export_environment.sh...                            0ms
Deleting ephemeral...                                                3ms
Deleting ephemeral...                                               39ms
Deleting .flutter-plugins-dependencies...                            0ms
PS C:\MixVy> flutter pub get
Resolving dependencies... 
Downloading packages... 
  _fe_analyzer_shared 93.0.0 (100.0.0 available)
  _flutterfire_internals 1.3.68 (1.3.69 available)
  agora_rtc_engine 6.5.3 (6.6.3 available)
  analyzer 10.0.1 (13.0.0 available)
  async 2.13.0 (2.13.1 available)
  build_runner 2.13.1 (2.14.0 available)
  built_value 8.12.4 (8.12.5 available)
  cli_util 0.4.2 (0.5.0 available)
  cloud_firestore 6.2.0 (6.3.0 available)
  cloud_firestore_platform_interface 7.1.0 (7.2.0 available)
  cloud_firestore_web 5.2.0 (5.3.0 available)
  cloud_functions 6.1.0 (6.2.0 available)
  cloud_functions_platform_interface 5.8.11 (5.8.12 available)
  cloud_functions_web 5.1.4 (5.1.5 available)
  connectivity_plus 7.0.0 (7.1.1 available)
  connectivity_plus_platform_interface 2.0.1 (2.1.0 available)
  dart_style 3.1.7 (3.1.8 available)
  firebase_analytics 12.2.0 (12.3.0 available)
  firebase_analytics_platform_interface 5.1.0 (5.1.1 available)
  firebase_analytics_web 0.6.1+4 (0.6.1+5 available)
  firebase_auth 6.3.0 (6.4.0 available)
  firebase_auth_platform_interface 8.1.8 (8.1.9 available)
  firebase_auth_web 6.1.4 (6.1.5 available)
  firebase_core 4.6.0 (4.7.0 available)
  firebase_core_web 3.5.1 (3.6.0 available)
  firebase_crashlytics 5.1.0 (5.2.0 available)
  firebase_crashlytics_platform_interface 3.8.19 (3.8.20 available)
  firebase_database 12.2.0 (12.3.0 available)
  firebase_database_platform_interface 0.3.1 (0.3.1+1 available)
  firebase_database_web 0.2.7+5 (0.2.7+6 available)
  firebase_messaging 16.1.3 (16.2.0 available)
  firebase_messaging_platform_interface 4.7.8 (4.7.9 available)
  firebase_messaging_web 4.1.4 (4.1.5 available)
  firebase_storage 13.2.0 (13.3.0 available)
  firebase_storage_platform_interface 5.2.19 (5.2.20 available)
  firebase_storage_web 3.11.4 (3.11.5 available)
  flutter_dotenv 6.0.0 (6.0.1 available)
  flutter_plugin_android_lifecycle 2.0.33 (2.0.34 available)
  flutter_riverpod 2.4.0 (3.3.1 available)
  flutter_stripe 12.4.0 (12.6.0 available)
  go_router 17.1.0 (17.2.2 available)
  google_fonts 6.3.3 (8.0.2 available)
  google_sign_in_android 7.2.9 (7.2.10 available)
  hooks 1.0.2 (1.0.3 available)
  image_picker_android 0.8.13+14 (0.8.13+16 available)
  iris_method_channel 2.2.4 (2.2.5 available)
  meta 1.17.0 (1.18.2 available)
  mocktail 1.0.4 (1.0.5 available)
  native_toolchain_c 0.17.6 (0.18.0 available)
  package_info_plus 9.0.0 (10.1.0 available)
  package_info_plus_platform_interface 3.2.1 (4.1.0 available)
  path_provider_android 2.2.22 (2.3.1 available)
  patrol 4.3.0 (4.5.0 available)
  patrol_finders 3.1.0 (3.2.0 available)
  patrol_log 0.7.1 (0.8.0 available)
  riverpod 2.4.0 (3.2.1 available)
  rx 0.4.0 (0.5.0 available)
  share_plus 12.0.1 (13.1.0 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  sqflite 2.4.2 (2.4.2+1 available)
  sqflite_common 2.5.6 (2.5.6+1 available)
  stripe_android 12.4.0 (12.6.0 available)
  stripe_ios 12.4.0 (12.6.0 available)
  stripe_platform_interface 12.4.0 (12.6.0 available)
  synchronized 3.4.0 (3.4.0+1 available)
  test_api 0.7.10 (0.7.11 available)
  url_launcher_android 6.3.28 (6.3.29 available)
  vector_math 2.2.0 (2.3.0 available)
  vm_service 15.0.2 (15.1.0 available)
  win32 5.15.0 (6.1.0 available)
  window_manager 0.4.3 (0.5.1 available)
Got dependencies!
71 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
PS C:\MixVy> flutter run -d windows
Launching lib\main.dart on Windows in debug mode...
IRIS_INCLUDE_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/iris/lib/iris_4.5.2-build.1_DCG_Windows/x64/include
IRIS_LIB_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/iris/lib/iris_4.5.2-build.1_DCG_Windows/x64/Release
NATIVE_INCLUDE_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/high_level_api/include
NATIVE_LIB_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/agora_rtc_sdk.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/glfw3.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-fdkaac.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-ffmpeg.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-soundtouch.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-wgc.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_echo_cancellation_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_echo_cancellation_ll_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_noise_suppression_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_noise_suppression_ll_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_audio_beauty_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_clear_vision_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_content_inspect_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_face_capture_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_face_detection_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_lip_sync_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_screen_capture_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_segmentation_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_spatial_audio_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_av1_decoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_av1_encoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_decoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_encoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_quality_analyzer_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libaosl.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/video_dec.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/video_enc.dll
lib/main.dart(207,15): error GC6690633: No named parameter with the name 'path'. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Microsoft.CppCommon.targets(254,5): error MSB8066: Custom build for 'C:\MixVy\build\windows\x64\CMakeFiles\5cd1ab06c07aff68f73e951a35ecdf36\flutter_windows.dll.rule;C:\MixVy\build\windows\x64\CMakeFiles\f81a5d5e2e4bab80d86029262111bb31\flutter_assemble.rule;C:\MixVy\windows\flutter\CMakeLists.txt' exited with code 1. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
C:\MixVy\windows\flutter\ephemeral\.plugin_symlinks\iris_method_channel\src\iris_event.cc(212,56): warning C4244: '=': conversion from 'intptr_t' to 'int', possible loss of data [C:\MixVy\build\windows\x64\plugins\iris_method_channel\shared\iris_method_channel.vcxproj]
Building Windows application...                                    79.7s
Error: Build process failed.
PS C:\MixVy> Select-String -Path lib\main.dart -Pattern "path:"                                      
                   
lib\main.dart:207:              path: "C:/MixVy/lib/stitch_ui/home_feed_desktop/code.html",

PS C:\MixVy> flutter clean         
Deleting build...                                                  178ms
Deleting .dart_tool...                                              21ms
Deleting ephemeral...                                                1ms
Deleting Generated.xcconfig...                                       1ms
Deleting flutter_export_environment.sh...                            0ms
Deleting ephemeral...                                                4ms
Deleting ephemeral...                                               30ms
Deleting .flutter-plugins-dependencies...                            0ms
PS C:\MixVy> flutter pub get
Resolving dependencies... 
Downloading packages... (3.4s)
  _fe_analyzer_shared 93.0.0 (100.0.0 available)
  _flutterfire_internals 1.3.68 (1.3.69 available)
  agora_rtc_engine 6.5.3 (6.6.3 available)
  analyzer 10.0.1 (13.0.0 available)
  async 2.13.0 (2.13.1 available)
  build_runner 2.13.1 (2.14.0 available)
  built_value 8.12.4 (8.12.5 available)
  cli_util 0.4.2 (0.5.0 available)
  cloud_firestore 6.2.0 (6.3.0 available)
  cloud_firestore_platform_interface 7.1.0 (7.2.0 available)
  cloud_firestore_web 5.2.0 (5.3.0 available)
  cloud_functions 6.1.0 (6.2.0 available)
  cloud_functions_platform_interface 5.8.11 (5.8.12 available)
  cloud_functions_web 5.1.4 (5.1.5 available)
  connectivity_plus 7.0.0 (7.1.1 available)
  connectivity_plus_platform_interface 2.0.1 (2.1.0 available)
  dart_style 3.1.7 (3.1.8 available)
  firebase_analytics 12.2.0 (12.3.0 available)
  firebase_analytics_platform_interface 5.1.0 (5.1.1 available)
  firebase_analytics_web 0.6.1+4 (0.6.1+5 available)
  firebase_auth 6.3.0 (6.4.0 available)
  firebase_auth_platform_interface 8.1.8 (8.1.9 available)
  firebase_auth_web 6.1.4 (6.1.5 available)
  firebase_core 4.6.0 (4.7.0 available)
  firebase_core_web 3.5.1 (3.6.0 available)
  firebase_crashlytics 5.1.0 (5.2.0 available)
  firebase_crashlytics_platform_interface 3.8.19 (3.8.20 available)
  firebase_database 12.2.0 (12.3.0 available)
  firebase_database_platform_interface 0.3.1 (0.3.1+1 available)
  firebase_database_web 0.2.7+5 (0.2.7+6 available)
  firebase_messaging 16.1.3 (16.2.0 available)
  firebase_messaging_platform_interface 4.7.8 (4.7.9 available)
  firebase_messaging_web 4.1.4 (4.1.5 available)
  firebase_storage 13.2.0 (13.3.0 available)
  firebase_storage_platform_interface 5.2.19 (5.2.20 available)
  firebase_storage_web 3.11.4 (3.11.5 available)
  flutter_dotenv 6.0.0 (6.0.1 available)
  flutter_plugin_android_lifecycle 2.0.33 (2.0.34 available)
  flutter_riverpod 2.4.0 (3.3.1 available)
  flutter_stripe 12.4.0 (12.6.0 available)
  go_router 17.1.0 (17.2.2 available)
  google_fonts 6.3.3 (8.0.2 available)
  google_sign_in_android 7.2.9 (7.2.10 available)
  hooks 1.0.2 (1.0.3 available)
  image_picker_android 0.8.13+14 (0.8.13+16 available)
  iris_method_channel 2.2.4 (2.2.5 available)
  meta 1.17.0 (1.18.2 available)
  mocktail 1.0.4 (1.0.5 available)
  native_toolchain_c 0.17.6 (0.18.0 available)
  package_info_plus 9.0.0 (10.1.0 available)
  package_info_plus_platform_interface 3.2.1 (4.1.0 available)
  path_provider_android 2.2.22 (2.3.1 available)
  patrol 4.3.0 (4.5.0 available)
  patrol_finders 3.1.0 (3.2.0 available)
  patrol_log 0.7.1 (0.8.0 available)
  riverpod 2.4.0 (3.2.1 available)
  rx 0.4.0 (0.5.0 available)
  share_plus 12.0.1 (13.1.0 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  sqflite 2.4.2 (2.4.2+1 available)
  sqflite_common 2.5.6 (2.5.6+1 available)
  stripe_android 12.4.0 (12.6.0 available)
  stripe_ios 12.4.0 (12.6.0 available)
  stripe_platform_interface 12.4.0 (12.6.0 available)
  synchronized 3.4.0 (3.4.0+1 available)
  test_api 0.7.10 (0.7.11 available)
  url_launcher_android 6.3.28 (6.3.29 available)
  vector_math 2.2.0 (2.3.0 available)
  vm_service 15.0.2 (15.1.0 available)
  win32 5.15.0 (6.1.0 available)
  window_manager 0.4.3 (0.5.1 available)
Got dependencies!
71 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
PS C:\MixVy> flutter run -d windows
Launching lib\main.dart on Windows in debug mode...
IRIS_INCLUDE_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/iris/lib/iris_4.5.2-build.1_DCG_Windows/x64/include
IRIS_LIB_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/iris/lib/iris_4.5.2-build.1_DCG_Windows/x64/Release
NATIVE_INCLUDE_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/high_level_api/include
NATIVE_LIB_DIR: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/agora_rtc_sdk.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/glfw3.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-fdkaac.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-ffmpeg.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-soundtouch.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora-wgc.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_echo_cancellation_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_echo_cancellation_ll_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_noise_suppression_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_ai_noise_suppression_ll_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_audio_beauty_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_clear_vision_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_content_inspect_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_face_capture_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_face_detection_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_lip_sync_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_screen_capture_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_segmentation_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_spatial_audio_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_av1_decoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_av1_encoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_decoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_encoder_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libagora_video_quality_analyzer_extension.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/libaosl.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/video_dec.dll
Add bundled library: C:/MixVy/windows/flutter/ephemeral/.plugin_symlinks/agora_rtc_engine/windows/third_party/native/lib/Agora_Native_SDK_for_Windows_FULL/sdk/x86_64/video_enc.dll
Building Windows application...                                    
lib/main.dart(202,15): error GC6690633: No named parameter with the name 'path'. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
Building Windows application...                                    
lib/stitch_ui/stitch_viewer.dart(420,53): error GC3A80135: 'SliverConstraints' isn't a type. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
Building Windows application...                                    
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Microsoft.CppCommon.targets(254,5): error MSB8066: Custom build for 'C:\MixVy\build\windows\x64\CMakeFiles\5cd1ab06c07aff68f73e951a35ecdf36\flutter_windows.dll.rule;C:\MixVy\build\windows\x64\CMakeFiles\f81a5d5e2e4bab80d86029262111bb31\flutter_assemble.rule;C:\MixVy\windows\flutter\CMakeLists.txt' exited with code 1. [C:\MixVy\build\windows\x64\flutter\flutter_assemble.vcxproj]
Building Windows application...                                    
C:\MixVy\windows\flutter\ephemeral\.plugin_symlinks\iris_method_channel\src\iris_event.cc(212,56): warning C4244: '=': conversion from 'intptr_t' to 'int', possible loss of data [C:\MixVy\build\windows\x64\plugins\iris_method_channel\shared\iris_method_channel.vcxproj]
Building Windows application...                                       80.6s
Error: Build process failed.
PS C:\MixVy> 