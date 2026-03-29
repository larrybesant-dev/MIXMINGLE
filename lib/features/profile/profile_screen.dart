import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mixvy/models/adult_profile_model.dart';
import 'package:mixvy/models/profile_privacy_model.dart';
import 'package:mixvy/models/room_policy_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/controllers/auth_controller.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: const SafeArea(child: ProfileFormView()),
    );
  }
}

class ProfileFormView extends ConsumerStatefulWidget {
  const ProfileFormView({super.key});

  @override
  ConsumerState<ProfileFormView> createState() => _ProfileFormViewState();
}

class _ProfileFormViewState extends ConsumerState<ProfileFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestsController = TextEditingController();
  final _vibeController = TextEditingController();
  final _firstDateController = TextEditingController();
  final _musicTasteController = TextEditingController();
  final _adultKinksController = TextEditingController();
  final _adultPreferencesController = TextEditingController();
  final _adultBoundariesController = TextEditingController();

  String? _loadedUserId;
  String? _selectedGender;
  String? _selectedRelationshipStatus;
  String _selectedThemeId = 'midnight';
  CamViewPolicy _selectedCamViewPolicy = CamViewPolicy.approvedOnly;
  bool _showAge = false;
  bool _showGender = false;
  bool _showLocation = false;
  bool _showRelationshipStatus = false;
  bool _adultModeEnabled = false;
  bool _adultConsentAccepted = false;
  final Set<AdultRelationshipIntent> _adultLookingFor = <AdultRelationshipIntent>{};

  bool _isUploadingPhoto = false;
  bool _isUploadingCover = false;
  bool _isUploadingVideo = false;
  bool _isUploadingGallery = false;

  static const int _maxPhotoBytes = 20 * 1024 * 1024;
  static const int _maxInlineProfilePhotoBytes = 700 * 1024;
  static const int _maxInlineCoverPhotoBytes = 700 * 1024;
  static const int _maxInlineGalleryPhotoBytes = 500 * 1024;
  static const int _maxVideoBytes = 120 * 1024 * 1024;
  static const List<String> _genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Trans woman',
    'Trans man',
    'Prefer not to say',
  ];
  static const List<String> _relationshipOptions = [
    'Single',
    'Talking',
    'Dating',
    'Open',
    'Complicated',
    'Prefer not to say',
  ];
  static const List<String> _themeOptions = ['midnight', 'sunset', 'emerald'];
  static const List<String> _interestSuggestions = [
    'nightlife',
    'deep talks',
    'afrobeats',
    'house music',
    'food spots',
    'travel',
    'comedy',
    'fitness',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileControllerProvider.notifier).loadCurrentProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _aboutMeController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _interestsController.dispose();
    _vibeController.dispose();
    _firstDateController.dispose();
    _musicTasteController.dispose();
    _adultKinksController.dispose();
    _adultPreferencesController.dispose();
    _adultBoundariesController.dispose();
    super.dispose();
  }

  Future<String?> _resolveUploadUserId() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return null;
      // Avoid reload() on web here; it can race auth state and destabilize upload flow.
      await user.getIdToken();
      return user.uid;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve upload user id',
        name: 'ProfileUpload',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _mapStorageError(FirebaseException e, {required String kind}) {
    final code = e.code.toLowerCase();
    return switch (code) {
      'unauthenticated' || 'permission-denied' || 'unauthorized' => 'Upload blocked by auth permissions. Please sign out and sign in again.',
      'quota-exceeded' => 'Storage quota exceeded. Please try again later.',
      'cancelled' => 'Upload was cancelled.',
      'retry-limit-exceeded' => 'Upload timed out. Check your network and retry.',
      'object-not-found' => 'Storage path missing. Please retry.',
      _ => '$kind upload failed (${e.code}): ${e.message ?? 'unknown error'}',
    };
  }

  String _mapPlatformError(PlatformException e, {required String kind}) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').trim();
    if (code.contains('permission') || code.contains('denied')) {
      return '$kind upload blocked by browser/device permissions.';
    }
    if (code.contains('network') || message.toLowerCase().contains('network')) {
      return '$kind upload failed due to network issues. Please retry.';
    }
    return '$kind upload failed (${e.code}): ${message.isEmpty ? 'unknown error' : message}';
  }

  List<String> _requiredSetupItems(ProfileState state) {
    final items = <String>[];
    if ((state.username ?? '').trim().length < 2) {
      items.add('Add a display name');
    }
    if ((state.email ?? '').trim().isEmpty) {
      items.add('Add an email on your account');
    }
    return items;
  }

  double _profileCompleteness(ProfileState state) {
    var score = 0;
    if ((state.username ?? '').trim().length >= 2) score++;
    if ((state.avatarUrl ?? '').trim().isNotEmpty) score++;
    if ((state.coverPhotoUrl ?? '').trim().isNotEmpty) score++;
    if ((state.bio ?? '').trim().isNotEmpty) score++;
    if ((state.aboutMe ?? '').trim().isNotEmpty) score++;
    if (state.interests.isNotEmpty) score++;
    if ((state.introVideoUrl ?? '').trim().isNotEmpty) score++;
    return score / 7;
  }

  Future<void> _openIntroVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid intro video URL.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open intro video.')),
      );
    }
  }

  /// Resize cover photo to fit 16:7 aspect ratio and compress for storage.
  /// Target dimensions: 1200x525 (16:7 ratio) for optimal quality vs file size.
  Uint8List _resizeCoverPhoto(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final targetAspect = 16 / 7;
      final currentAspect = image.width / image.height;

      late int cropWidth;
      late int cropHeight;
      late int cropX;
      late int cropY;

      if (currentAspect > targetAspect) {
        // Image is too wide, crop horizontally
        cropHeight = image.height;
        cropWidth = (image.height * targetAspect).toInt();
        cropX = ((image.width - cropWidth) / 2).toInt();
        cropY = 0;
      } else {
        // Image is too tall, crop vertically
        cropWidth = image.width;
        cropHeight = (image.width / targetAspect).toInt();
        cropX = 0;
        cropY = ((image.height - cropHeight) / 2).toInt();
      }

      // Crop to 16:7 ratio
      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Resize to target dimensions (1200x525)
      final resized = img.copyResize(cropped, width: 1200, height: 525, interpolation: img.Interpolation.linear);

      // Encode as JPEG with quality 85 for smaller file size
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      developer.log('Error resizing cover photo: $e', name: 'ProfileUpload', error: e);
      return bytes; // Return original if resize fails
    }
  }

  Future<String> _uploadToStorage({
    required Uint8List bytes,
    required String userId,
    required String folder,
    required String extension,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/$folder/$timestamp.$extension';
    final storage = FirebaseStorage.instance;
    final ref = storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    final isImage = contentType.toLowerCase().startsWith('image/');

    try {
      if (kIsWeb && isImage) {
        final dataUrl = 'data:$contentType;base64,${base64Encode(bytes)}';
        await ref
            .putString(
              dataUrl,
              format: PutStringFormat.dataUrl,
              metadata: metadata,
            )
            .timeout(const Duration(seconds: 45));
      } else {
        await ref.putData(bytes, metadata).timeout(const Duration(seconds: 45));
      }
    } on FirebaseException catch (e) {
      final code = e.code.toLowerCase();
      final shouldRetry = code == 'unauthenticated' || code == 'permission-denied' || code == 'unauthorized';
      if (!shouldRetry) rethrow;
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (kIsWeb && isImage) {
        final dataUrl = 'data:$contentType;base64,${base64Encode(bytes)}';
        await ref
            .putString(
              dataUrl,
              format: PutStringFormat.dataUrl,
              metadata: metadata,
            )
            .timeout(const Duration(seconds: 45));
      } else {
        await ref.putData(bytes, metadata).timeout(const Duration(seconds: 45));
      }
    } on TimeoutException {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'retry-limit-exceeded',
        message: 'Upload timed out before completion.',
      );
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await ref.getDownloadURL().timeout(const Duration(seconds: 20));
      } on TimeoutException catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
      } on FirebaseException catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
        final code = e.code.toLowerCase();
        if (code != 'object-not-found' && code != 'unknown') {
          rethrow;
        }
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
      }

      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    developer.log(
      'Failed to resolve uploaded file download URL after retries',
      name: 'ProfileUpload',
      error: lastError,
      stackTrace: lastStackTrace,
    );

    if (lastError is FirebaseException) {
      throw lastError;
    }

    throw FirebaseException(
      plugin: 'firebase_storage',
      code: 'unknown',
      message: 'Unable to get photo URL after upload.',
    );
  }

  Future<void> _uploadImage({
    required bool isBusy,
    required ValueSetter<bool> setBusy,
    required String folder,
    required String successMessage,
    required ProfileState Function(ProfileState current, String url) transform,
  }) async {
    if (isBusy) return;
    final userId = await _resolveUploadUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your session expired. Please sign in again to upload.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (file == null) return;
      final bytes = await file.readAsBytes().timeout(const Duration(seconds: 20));
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large. Choose one under 20MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => setBusy(true));

      // Resize cover photos to fit 16:7 aspect ratio before upload
      var uploadBytes = bytes;
      if (folder == 'cover_photos') {
        uploadBytes = _resizeCoverPhoto(bytes);
      }

      String url;
      // Web fallback: keep image uploads in-profile as data URLs to avoid storage web host API crashes.
      if (kIsWeb) {
        final inlineLimit = switch (folder) {
          'profile_photos' => _maxInlineProfilePhotoBytes,
          'cover_photos' => _maxInlineCoverPhotoBytes,
          'gallery_photos' => _maxInlineGalleryPhotoBytes,
          _ => _maxInlineProfilePhotoBytes,
        };
        if (uploadBytes.lengthInBytes > inlineLimit) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large for web upload. Please choose a smaller file.')),
          );
          return;
        }
        url = 'data:image/jpeg;base64,${base64Encode(uploadBytes)}';
      } else {
        url = await _uploadToStorage(
          bytes: uploadBytes,
          userId: userId,
          folder: folder,
          extension: 'jpg',
          contentType: 'image/jpeg',
        );
      }

      final controller = ref.read(profileControllerProvider.notifier);
      final current = ref.read(profileControllerProvider);
      final next = transform(current, url);
      controller.updateDraft(next);
      await controller.updateProfile(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } on FirebaseException catch (e) {
      developer.log(
        'Firebase upload error',
        name: 'ProfileUpload',
        error: e,
        stackTrace: StackTrace.current,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapStorageError(e, kind: 'Photo'))),
      );
    } on PlatformException catch (e) {
      developer.log(
        'Platform upload error',
        name: 'ProfileUpload',
        error: e,
        stackTrace: StackTrace.current,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapPlatformError(e, kind: 'Photo'))),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload timed out. Please try again.')),
      );
    } catch (e) {
      developer.log(
        'Unexpected upload error',
        name: 'ProfileUpload',
        error: e,
        stackTrace: StackTrace.current,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => setBusy(false));
      }
    }
  }

  Future<void> _uploadPhoto() async {
    final current = ref.read(profileControllerProvider);
    await _uploadImage(
      isBusy: _isUploadingPhoto,
      setBusy: (value) => _isUploadingPhoto = value,
      folder: 'profile_photos',
      successMessage: 'Profile photo uploaded.',
      transform: (_, url) {
        return current.copyWith(avatarUrl: url);
      },
    );
  }

  Future<void> _uploadCoverPhoto() async {
    final current = ref.read(profileControllerProvider);
    await _uploadImage(
      isBusy: _isUploadingCover,
      setBusy: (value) => _isUploadingCover = value,
      folder: 'cover_photos',
      successMessage: 'Cover photo uploaded.',
      transform: (_, url) {
        return current.copyWith(coverPhotoUrl: url);
      },
    );
  }

  Future<void> _uploadGalleryPhoto() async {
    final current = ref.read(profileControllerProvider);
    await _uploadImage(
      isBusy: _isUploadingGallery,
      setBusy: (value) => _isUploadingGallery = value,
      folder: 'gallery_photos',
      successMessage: 'Gallery photo uploaded.',
      transform: (_, url) {
        return current.copyWith(
          galleryUrls: {...current.galleryUrls, url}.toList(growable: false),
        );
      },
    );
  }

  Future<void> _uploadVideo() async {
    if (_isUploadingVideo) return;
    final userId = await _resolveUploadUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your session expired. Please sign in again to upload.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 45));
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxVideoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is too large. Choose one under 120MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isUploadingVideo = true);
      final videoUrl = await _uploadToStorage(
        bytes: bytes,
        userId: userId,
        folder: 'intro_videos',
        extension: 'mp4',
        contentType: 'video/mp4',
      );
      final controller = ref.read(profileControllerProvider.notifier);
      final current = ref.read(profileControllerProvider);
      await controller.updateProfile(current.copyWith(introVideoUrl: videoUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intro video uploaded.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapStorageError(e, kind: 'Video'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      }
    }
  }

  List<String> _parseList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  void _addInterestSuggestion(String suggestion) {
    final interests = _parseList(_interestsController.text).toList(growable: true);
    if (interests.contains(suggestion) || interests.length >= 8) {
      return;
    }
    interests.add(suggestion);
    _interestsController.text = interests.join(', ');
    _interestsController.selection = TextSelection.collapsed(offset: _interestsController.text.length);
    setState(() {});
  }

  void _hydrateForm(ProfileState state) {
    if (state.userId == null || state.userId == _loadedUserId) {
      return;
    }
    _loadedUserId = state.userId;
    _nameController.text = state.username ?? '';
    _bioController.text = state.bio ?? '';
    _aboutMeController.text = state.aboutMe ?? '';
    _ageController.text = state.age?.toString() ?? '';
    _locationController.text = state.location ?? '';
    _interestsController.text = state.interests.join(', ');
    _vibeController.text = state.vibePrompt ?? '';
    _firstDateController.text = state.firstDatePrompt ?? '';
    _musicTasteController.text = state.musicTastePrompt ?? '';
    _adultKinksController.text = state.adultKinks.join(', ');
    _adultPreferencesController.text = state.adultPreferences.join(', ');
    _adultBoundariesController.text = state.adultBoundaries.join(', ');
    _selectedGender = state.gender;
    _selectedRelationshipStatus = state.relationshipStatus;
    _selectedThemeId = state.themeId;
    _selectedCamViewPolicy = state.camViewPolicy;
    _showAge = state.privacy.showAge;
    _showGender = state.privacy.showGender;
    _showLocation = state.privacy.showLocation;
    _showRelationshipStatus = state.privacy.showRelationshipStatus;
    _adultModeEnabled = state.adultModeEnabled;
    _adultConsentAccepted = state.adultConsentAccepted;
    _adultLookingFor
      ..clear()
      ..addAll(state.adultLookingFor);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_adultModeEnabled && !_adultConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm you are 18+ before enabling adult mode.')),
      );
      return;
    }

    final parsedAge = int.tryParse(_ageController.text.trim());
    if (_ageController.text.trim().isNotEmpty && parsedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age must be a valid number.')),
      );
      return;
    }

    final controller = ref.read(profileControllerProvider.notifier);
    final current = ref.read(profileControllerProvider);
    await controller.updateProfile(
      current.copyWith(
        username: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        aboutMe: _aboutMeController.text.trim(),
        age: parsedAge,
        gender: _selectedGender,
        location: _locationController.text.trim(),
        relationshipStatus: _selectedRelationshipStatus,
        interests: _parseList(_interestsController.text),
        vibePrompt: _vibeController.text.trim(),
        firstDatePrompt: _firstDateController.text.trim(),
        musicTastePrompt: _musicTasteController.text.trim(),
        themeId: _selectedThemeId,
        camViewPolicy: _selectedCamViewPolicy,
        privacy: ProfilePrivacyModel(
          showAge: _showAge,
          showGender: _showGender,
          showLocation: _showLocation,
          showRelationshipStatus: _showRelationshipStatus,
        ),
        adultModeEnabled: _adultModeEnabled,
        adultConsentAccepted: _adultConsentAccepted,
        adultKinks: _parseList(_adultKinksController.text),
        adultPreferences: _parseList(_adultPreferencesController.text),
        adultBoundaries: _parseList(_adultBoundariesController.text),
        adultLookingFor: _adultLookingFor.toList(growable: false),
      ),
    );
    if (!mounted) return;
    final state = ref.read(profileControllerProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    _hydrateForm(state);
    final requiredItems = _requiredSetupItems(state);
    final isSetupComplete = requiredItems.isEmpty;

    if (state.isLoading && state.userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSetupComplete)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finish setup to unlock all pages',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        ...requiredItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.radio_button_unchecked, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _HeroCard(
                  state: state,
                  profileStrength: _profileCompleteness(state),
                  onUploadAvatar: _uploadPhoto,
                  onUploadCover: _uploadCoverPhoto,
                  onUploadGallery: _uploadGalleryPhoto,
                  onUploadVideo: _uploadVideo,
                  isUploadingPhoto: _isUploadingPhoto,
                  isUploadingCover: _isUploadingCover,
                  isUploadingGallery: _isUploadingGallery,
                  isUploadingVideo: _isUploadingVideo,
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Identity',
                  subtitle: 'Core profile details other people can discover.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                        validator: (value) => (value ?? '').trim().length < 2 ? 'Enter at least 2 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(labelText: 'Bio'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _aboutMeController,
                        decoration: const InputDecoration(labelText: 'About me'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(labelText: 'Gender'),
                              items: _genderOptions
                                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                                  .toList(growable: false),
                              onChanged: (value) => setState(() => _selectedGender = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRelationshipStatus,
                        decoration: const InputDecoration(labelText: 'Relationship status'),
                        items: _relationshipOptions
                            .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                            .toList(growable: false),
                        onChanged: (value) => setState(() => _selectedRelationshipStatus = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Privacy and cam control',
                  subtitle: 'Choose what stays public and how camera access should be handled later in live contexts.',
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _showAge,
                        onChanged: (value) => setState(() => _showAge = value),
                        title: const Text('Show age'),
                      ),
                      SwitchListTile(
                        value: _showGender,
                        onChanged: (value) => setState(() => _showGender = value),
                        title: const Text('Show gender'),
                      ),
                      SwitchListTile(
                        value: _showLocation,
                        onChanged: (value) => setState(() => _showLocation = value),
                        title: const Text('Show location'),
                      ),
                      SwitchListTile(
                        value: _showRelationshipStatus,
                        onChanged: (value) => setState(() => _showRelationshipStatus = value),
                        title: const Text('Show relationship status'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CamViewPolicy>(
                        initialValue: _selectedCamViewPolicy,
                        decoration: const InputDecoration(labelText: 'Who can view my cam'),
                        items: CamViewPolicy.values
                            .map(
                              (value) => DropdownMenuItem<CamViewPolicy>(
                                value: value,
                                child: Text(_camPolicyLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCamViewPolicy = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Profile vibe',
                  subtitle: 'Set the look and the conversation hooks for your page.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedThemeId,
                        decoration: const InputDecoration(labelText: 'Theme'),
                        items: _themeOptions
                            .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedThemeId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _interestsController,
                        decoration: const InputDecoration(labelText: 'Interests', hintText: 'Comma-separated interests'),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interestSuggestions
                            .map((suggestion) => ActionChip(label: Text(suggestion), onPressed: () => _addInterestSuggestion(suggestion)))
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vibeController,
                        decoration: const InputDecoration(labelText: 'Tonight vibe'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _firstDateController,
                        decoration: const InputDecoration(labelText: 'First date move'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _musicTasteController,
                        decoration: const InputDecoration(labelText: 'Music taste'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Adult mode',
                  subtitle: 'Stored separately and reserved for adult-only contexts. It is not shown on the public profile page.',
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _adultModeEnabled,
                        onChanged: (value) => setState(() => _adultModeEnabled = value),
                        title: const Text('Enable naughty side'),
                      ),
                      CheckboxListTile(
                        value: _adultConsentAccepted,
                        onChanged: (value) => setState(() => _adultConsentAccepted = value ?? false),
                        title: const Text('I confirm I am 18+'),
                      ),
                      if (_adultModeEnabled) ...[
                        TextFormField(
                          controller: _adultKinksController,
                          decoration: const InputDecoration(labelText: 'Kinks'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adultPreferencesController,
                          decoration: const InputDecoration(labelText: 'Preferences'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adultBoundariesController,
                          decoration: const InputDecoration(labelText: 'Boundaries'),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Looking for', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AdultRelationshipIntent.values
                              .map(
                                (intent) => FilterChip(
                                  label: Text(_adultIntentLabel(intent)),
                                  selected: _adultLookingFor.contains(intent),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _adultLookingFor.add(intent);
                                      } else {
                                        _adultLookingFor.remove(intent);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                if ((state.introVideoUrl ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Intro video ready'),
                    trailing: TextButton(
                      onPressed: () => _openIntroVideo(state.introVideoUrl!.trim()),
                      child: const Text('Open'),
                    ),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isLoading ? null : _saveProfile,
                    icon: state.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _adultIntentLabel(AdultRelationshipIntent value) {
    switch (value) {
      case AdultRelationshipIntent.love:
        return 'Love';
      case AdultRelationshipIntent.fun:
        return 'Fun';
      case AdultRelationshipIntent.hookups:
        return 'Hookups';
      case AdultRelationshipIntent.openConnection:
        return 'Open connection';
    }
  }

  String _camPolicyLabel(CamViewPolicy value) {
    switch (value) {
      case CamViewPolicy.everyone:
        return 'Everyone can view my cam';
      case CamViewPolicy.friendsOnly:
        return 'Friends only';
      case CamViewPolicy.approvedOnly:
        return 'People I approve';
      case CamViewPolicy.nobody:
        return 'Nobody';
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.state,
    required this.profileStrength,
    required this.onUploadAvatar,
    required this.onUploadCover,
    required this.onUploadGallery,
    required this.onUploadVideo,
    required this.isUploadingPhoto,
    required this.isUploadingCover,
    required this.isUploadingGallery,
    required this.isUploadingVideo,
  });

  final ProfileState state;
  final double profileStrength;
  final Future<void> Function() onUploadAvatar;
  final Future<void> Function() onUploadCover;
  final Future<void> Function() onUploadGallery;
  final Future<void> Function() onUploadVideo;
  final bool isUploadingPhoto;
  final bool isUploadingCover;
  final bool isUploadingGallery;
  final bool isUploadingVideo;

  @override
  Widget build(BuildContext context) {
    Future<void> safeRunUpload(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stackTrace) {
        developer.log(
          'Unhandled profile upload error',
          name: 'ProfileUpload',
          error: error,
          stackTrace: stackTrace,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Picture upload failed. Please try again.')),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: (state.coverPhotoUrl ?? '').trim().isNotEmpty
                    ? Image.network(
                        state.coverPhotoUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.landscape_rounded, size: 40),
                      )
                    : const Icon(Icons.landscape_rounded, size: 40),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: (state.avatarUrl ?? '').trim().isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        state.avatarUrl!.trim(),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => const Icon(Icons.person, size: 32),
                      ),
                    )
                  : const Icon(Icons.person, size: 32),
            ),
          ),
          Text(
            (state.username ?? '').trim().isEmpty ? 'Your profile' : state.username!.trim(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: profileStrength,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile strength ${(100 * profileStrength).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Followers', value: '${state.followers.length}')),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: 'Photos', value: '${state.galleryUrls.length}')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: isUploadingPhoto ? null : () => safeRunUpload(onUploadAvatar),
                icon: const Icon(Icons.photo_camera_back_outlined),
                label: Text(isUploadingPhoto ? 'Uploading...' : 'Profile Picture Upload'),
              ),
              OutlinedButton.icon(
                onPressed: isUploadingCover ? null : () => safeRunUpload(onUploadCover),
                icon: const Icon(Icons.image_outlined),
                label: Text(isUploadingCover ? 'Uploading...' : 'Cover'),
              ),
              OutlinedButton.icon(
                onPressed: isUploadingGallery ? null : () => safeRunUpload(onUploadGallery),
                icon: const Icon(Icons.collections_outlined),
                label: Text(isUploadingGallery ? 'Uploading...' : 'Gallery'),
              ),
              OutlinedButton.icon(
                onPressed: isUploadingVideo ? null : () => safeRunUpload(onUploadVideo),
                icon: const Icon(Icons.videocam_outlined),
                label: Text(isUploadingVideo ? 'Uploading...' : 'Intro video'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
