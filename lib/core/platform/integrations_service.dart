/// Integrations Service
///
/// Manages third-party platform integrations including payment providers,
/// marketing platforms, CRM systems, and streaming platforms.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Integration status
enum IntegrationStatus {
  disconnected,
  connecting,
  connected,
  error,
  suspended,
}

/// Integration type
enum IntegrationType {
  payment,
  marketing,
  crm,
  streaming,
  social,
  analytics,
}

/// Base integration
class Integration {
  final String id;
  final String name;
  final IntegrationType type;
  final IntegrationStatus status;
  final String? accountId;
  final Map<String, dynamic> config;
  final Map<String, dynamic> metadata;
  final DateTime connectedAt;
  final DateTime? lastSyncAt;
  final String? error;

  const Integration({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.accountId,
    this.config = const {},
    this.metadata = const {},
    required this.connectedAt,
    this.lastSyncAt,
    this.error,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'status': status.name,
        'accountId': accountId,
        'config': config,
        'metadata': metadata,
        'connectedAt': connectedAt.toIso8601String(),
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'error': error,
      };

  factory Integration.fromMap(Map<String, dynamic> map) => Integration(
        id: map['id'] as String,
        name: map['name'] as String,
        type: IntegrationType.values.firstWhere(
          (t) => t.name == map['type'],
        ),
        status: IntegrationStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => IntegrationStatus.disconnected,
        ),
        accountId: map['accountId'] as String?,
        config: (map['config'] as Map<String, dynamic>?) ?? {},
        metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
        connectedAt: DateTime.parse(map['connectedAt'] as String),
        lastSyncAt: map['lastSyncAt'] != null
            ? DateTime.parse(map['lastSyncAt'] as String)
            : null,
        error: map['error'] as String?,
      );
}

/// Payment provider integration
class PaymentProvider {
  final String id;
  final String name;
  final PaymentProviderType providerType;
  final IntegrationStatus status;
  final String? merchantId;
  final List<String> supportedCurrencies;
  final List<String> supportedMethods;
  final Map<String, dynamic> fees;
  final bool liveMode;

  const PaymentProvider({
    required this.id,
    required this.name,
    required this.providerType,
    required this.status,
    this.merchantId,
    this.supportedCurrencies = const ['USD'],
    this.supportedMethods = const ['card'],
    this.fees = const {},
    this.liveMode = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'providerType': providerType.name,
        'status': status.name,
        'merchantId': merchantId,
        'supportedCurrencies': supportedCurrencies,
        'supportedMethods': supportedMethods,
        'fees': fees,
        'liveMode': liveMode,
      };
}

enum PaymentProviderType {
  stripe,
  paypal,
  applePay,
  googlePay,
  crypto,
}

/// Marketing platform integration
class MarketingPlatform {
  final String id;
  final String name;
  final MarketingPlatformType platformType;
  final IntegrationStatus status;
  final String? accountId;
  final List<String> enabledFeatures;
  final Map<String, dynamic> trackingConfig;

  const MarketingPlatform({
    required this.id,
    required this.name,
    required this.platformType,
    required this.status,
    this.accountId,
    this.enabledFeatures = const [],
    this.trackingConfig = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'platformType': platformType.name,
        'status': status.name,
        'accountId': accountId,
        'enabledFeatures': enabledFeatures,
        'trackingConfig': trackingConfig,
      };
}

enum MarketingPlatformType {
  googleAds,
  facebookAds,
  tiktokAds,
  mailchimp,
  hubspot,
}

/// CRM system integration
class CRMSystem {
  final String id;
  final String name;
  final CRMSystemType systemType;
  final IntegrationStatus status;
  final String? instanceUrl;
  final List<String> syncedEntities;
  final SyncDirection syncDirection;
  final Duration syncInterval;

  const CRMSystem({
    required this.id,
    required this.name,
    required this.systemType,
    required this.status,
    this.instanceUrl,
    this.syncedEntities = const [],
    this.syncDirection = SyncDirection.bidirectional,
    this.syncInterval = const Duration(hours: 1),
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'systemType': systemType.name,
        'status': status.name,
        'instanceUrl': instanceUrl,
        'syncedEntities': syncedEntities,
        'syncDirection': syncDirection.name,
        'syncIntervalMinutes': syncInterval.inMinutes,
      };
}

enum CRMSystemType {
  salesforce,
  hubspot,
  zoho,
  pipedrive,
  freshsales,
}

enum SyncDirection {
  toMixMingle,
  fromMixMingle,
  bidirectional,
}

/// Streaming platform integration
class StreamingPlatform {
  final String id;
  final String name;
  final StreamingPlatformType platformType;
  final IntegrationStatus status;
  final String? channelId;
  final String? streamKey;
  final bool autoPublish;
  final bool simultaneousStream;
  final StreamQuality quality;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.platformType,
    required this.status,
    this.channelId,
    this.streamKey,
    this.autoPublish = false,
    this.simultaneousStream = true,
    this.quality = StreamQuality.hd,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'platformType': platformType.name,
        'status': status.name,
        'channelId': channelId,
        'streamKey': streamKey,
        'autoPublish': autoPublish,
        'simultaneousStream': simultaneousStream,
        'quality': quality.name,
      };
}

enum StreamingPlatformType {
  youtube,
  twitch,
  facebook,
  instagram,
  tiktok,
  custom,
}

enum StreamQuality {
  sd,
  hd,
  fullHd,
  uhd,
}

/// Integration result
class IntegrationResult {
  final bool success;
  final Integration? integration;
  final String? error;
  final Map<String, dynamic> metadata;

  const IntegrationResult({
    required this.success,
    this.integration,
    this.error,
    this.metadata = const {},
  });
}

/// Integrations Service for managing third-party connections
class IntegrationsService {
  static IntegrationsService? _instance;
  static IntegrationsService get instance =>
      _instance ??= IntegrationsService._();

  IntegrationsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers
  final _integrationController = StreamController<Integration>.broadcast();

  Stream<Integration> get integrationStream => _integrationController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _integrationsCollection =>
      _firestore.collection('integrations');

  CollectionReference<Map<String, dynamic>> get _paymentProvidersCollection =>
      _firestore.collection('payment_providers');

  CollectionReference<Map<String, dynamic>> get _marketingPlatformsCollection =>
      _firestore.collection('marketing_platforms');

  CollectionReference<Map<String, dynamic>> get _crmSystemsCollection =>
      _firestore.collection('crm_systems');

  CollectionReference<Map<String, dynamic>> get _streamingPlatformsCollection =>
      _firestore.collection('streaming_platforms');

  // ============================================================
  // PAYMENT PROVIDERS
  // ============================================================

  /// Integrate payment providers
  Future<IntegrationResult> integratePaymentProviders({
    required PaymentProviderType provider,
    required String apiKey,
    String? secretKey,
    String? webhookSecret,
    bool liveMode = false,
    List<String>? currencies,
    List<String>? methods,
  }) async {
    debugPrint('💳 [Integrations] Integrating payment provider: ${provider.name}');

    try {
      final id = 'payment_${provider.name}_${DateTime.now().millisecondsSinceEpoch}';

      final paymentProvider = PaymentProvider(
        id: id,
        name: _getPaymentProviderName(provider),
        providerType: provider,
        status: IntegrationStatus.connecting,
        supportedCurrencies: currencies ?? ['USD', 'EUR', 'GBP'],
        supportedMethods: methods ?? ['card', 'bank_transfer'],
        liveMode: liveMode,
        fees: _getDefaultFees(provider),
      );

      // Store provider config
      await _paymentProvidersCollection.doc(id).set({
        ...paymentProvider.toMap(),
        'apiKeyHash': _hashKey(apiKey),
        'hasSecretKey': secretKey != null,
        'hasWebhookSecret': webhookSecret != null,
        'connectedAt': DateTime.now().toIso8601String(),
      });

      // Verify connection (simulated)
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status to connected
      await _paymentProvidersCollection.doc(id).update({
        'status': IntegrationStatus.connected.name,
      });

      final integration = Integration(
        id: id,
        name: paymentProvider.name,
        type: IntegrationType.payment,
        status: IntegrationStatus.connected,
        config: paymentProvider.toMap(),
        connectedAt: DateTime.now(),
      );

      // Store in main integrations
      await _integrationsCollection.doc(id).set(integration.toMap());

      _integrationController.add(integration);

      AnalyticsService.instance.logEvent(
        name: 'payment_provider_integrated',
        parameters: {'provider': provider.name, 'live_mode': liveMode},
      );

      debugPrint('✅ [Integrations] Payment provider connected: ${provider.name}');
      return IntegrationResult(success: true, integration: integration);
    } catch (e) {
      debugPrint('❌ [Integrations] Payment integration failed: $e');
      return IntegrationResult(success: false, error: e.toString());
    }
  }

  String _getPaymentProviderName(PaymentProviderType type) => switch (type) {
        PaymentProviderType.stripe => 'Stripe',
        PaymentProviderType.paypal => 'PayPal',
        PaymentProviderType.applePay => 'Apple Pay',
        PaymentProviderType.googlePay => 'Google Pay',
        PaymentProviderType.crypto => 'Crypto Payments',
      };

  Map<String, dynamic> _getDefaultFees(PaymentProviderType type) =>
      switch (type) {
        PaymentProviderType.stripe => {
            'percentage': 2.9,
            'fixed': 0.30,
            'currency': 'USD'
          },
        PaymentProviderType.paypal => {
            'percentage': 3.49,
            'fixed': 0.49,
            'currency': 'USD'
          },
        _ => {'percentage': 2.5, 'fixed': 0.25, 'currency': 'USD'},
      };

  String _hashKey(String key) {
    // In production, use proper hashing
    return key.hashCode.toString();
  }

  // ============================================================
  // MARKETING PLATFORMS
  // ============================================================

  /// Integrate marketing platforms
  Future<IntegrationResult> integrateMarketingPlatforms({
    required MarketingPlatformType platform,
    required String accountId,
    String? apiKey,
    String? accessToken,
    List<String>? features,
    Map<String, dynamic>? trackingConfig,
  }) async {
    debugPrint('📢 [Integrations] Integrating marketing platform: ${platform.name}');

    try {
      final id = 'marketing_${platform.name}_${DateTime.now().millisecondsSinceEpoch}';

      final marketingPlatform = MarketingPlatform(
        id: id,
        name: _getMarketingPlatformName(platform),
        platformType: platform,
        status: IntegrationStatus.connecting,
        accountId: accountId,
        enabledFeatures: features ?? _getDefaultMarketingFeatures(platform),
        trackingConfig: trackingConfig ?? {},
      );

      // Store platform config
      await _marketingPlatformsCollection.doc(id).set({
        ...marketingPlatform.toMap(),
        'hasApiKey': apiKey != null,
        'hasAccessToken': accessToken != null,
        'connectedAt': DateTime.now().toIso8601String(),
      });

      // Verify connection (simulated)
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status
      await _marketingPlatformsCollection.doc(id).update({
        'status': IntegrationStatus.connected.name,
      });

      final integration = Integration(
        id: id,
        name: marketingPlatform.name,
        type: IntegrationType.marketing,
        status: IntegrationStatus.connected,
        accountId: accountId,
        config: marketingPlatform.toMap(),
        connectedAt: DateTime.now(),
      );

      await _integrationsCollection.doc(id).set(integration.toMap());
      _integrationController.add(integration);

      AnalyticsService.instance.logEvent(
        name: 'marketing_platform_integrated',
        parameters: {'platform': platform.name},
      );

      debugPrint('✅ [Integrations] Marketing platform connected: ${platform.name}');
      return IntegrationResult(success: true, integration: integration);
    } catch (e) {
      debugPrint('❌ [Integrations] Marketing integration failed: $e');
      return IntegrationResult(success: false, error: e.toString());
    }
  }

  String _getMarketingPlatformName(MarketingPlatformType type) => switch (type) {
        MarketingPlatformType.googleAds => 'Google Ads',
        MarketingPlatformType.facebookAds => 'Meta Ads',
        MarketingPlatformType.tiktokAds => 'TikTok Ads',
        MarketingPlatformType.mailchimp => 'Mailchimp',
        MarketingPlatformType.hubspot => 'HubSpot Marketing',
      };

  List<String> _getDefaultMarketingFeatures(MarketingPlatformType type) =>
      switch (type) {
        MarketingPlatformType.googleAds => [
            'conversion_tracking',
            'remarketing',
            'audience_sync'
          ],
        MarketingPlatformType.facebookAds => [
            'pixel_tracking',
            'custom_audiences',
            'lookalike_audiences'
          ],
        MarketingPlatformType.tiktokAds => [
            'pixel_tracking',
            'event_api',
            'audience_sync'
          ],
        MarketingPlatformType.mailchimp => [
            'email_campaigns',
            'automation',
            'audience_sync'
          ],
        MarketingPlatformType.hubspot => [
            'email_marketing',
            'workflows',
            'analytics'
          ],
      };

  // ============================================================
  // CRM SYSTEMS
  // ============================================================

  /// Integrate CRM systems
  Future<IntegrationResult> integrateCRMSystems({
    required CRMSystemType system,
    required String instanceUrl,
    required String accessToken,
    String? refreshToken,
    List<String>? entitiesToSync,
    SyncDirection direction = SyncDirection.bidirectional,
    Duration syncInterval = const Duration(hours: 1),
  }) async {
    debugPrint('📊 [Integrations] Integrating CRM: ${system.name}');

    try {
      final id = 'crm_${system.name}_${DateTime.now().millisecondsSinceEpoch}';

      final crmSystem = CRMSystem(
        id: id,
        name: _getCRMSystemName(system),
        systemType: system,
        status: IntegrationStatus.connecting,
        instanceUrl: instanceUrl,
        syncedEntities: entitiesToSync ?? _getDefaultCRMEntities(system),
        syncDirection: direction,
        syncInterval: syncInterval,
      );

      // Store CRM config
      await _crmSystemsCollection.doc(id).set({
        ...crmSystem.toMap(),
        'hasAccessToken': true,
        'hasRefreshToken': refreshToken != null,
        'connectedAt': DateTime.now().toIso8601String(),
      });

      // Verify connection (simulated)
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status
      await _crmSystemsCollection.doc(id).update({
        'status': IntegrationStatus.connected.name,
      });

      final integration = Integration(
        id: id,
        name: crmSystem.name,
        type: IntegrationType.crm,
        status: IntegrationStatus.connected,
        config: crmSystem.toMap(),
        connectedAt: DateTime.now(),
      );

      await _integrationsCollection.doc(id).set(integration.toMap());
      _integrationController.add(integration);

      AnalyticsService.instance.logEvent(
        name: 'crm_integrated',
        parameters: {'system': system.name},
      );

      debugPrint('✅ [Integrations] CRM connected: ${system.name}');
      return IntegrationResult(success: true, integration: integration);
    } catch (e) {
      debugPrint('❌ [Integrations] CRM integration failed: $e');
      return IntegrationResult(success: false, error: e.toString());
    }
  }

  String _getCRMSystemName(CRMSystemType type) => switch (type) {
        CRMSystemType.salesforce => 'Salesforce',
        CRMSystemType.hubspot => 'HubSpot CRM',
        CRMSystemType.zoho => 'Zoho CRM',
        CRMSystemType.pipedrive => 'Pipedrive',
        CRMSystemType.freshsales => 'Freshsales',
      };

  List<String> _getDefaultCRMEntities(CRMSystemType type) => [
        'contacts',
        'accounts',
        'opportunities',
        'activities',
      ];

  // ============================================================
  // STREAMING PLATFORMS
  // ============================================================

  /// Integrate streaming platforms
  Future<IntegrationResult> integrateStreamingPlatforms({
    required StreamingPlatformType platform,
    required String channelId,
    String? streamKey,
    String? accessToken,
    bool autoPublish = false,
    bool simultaneousStream = true,
    StreamQuality quality = StreamQuality.hd,
  }) async {
    debugPrint('📺 [Integrations] Integrating streaming platform: ${platform.name}');

    try {
      final id = 'streaming_${platform.name}_${DateTime.now().millisecondsSinceEpoch}';

      final streamingPlatform = StreamingPlatform(
        id: id,
        name: _getStreamingPlatformName(platform),
        platformType: platform,
        status: IntegrationStatus.connecting,
        channelId: channelId,
        streamKey: streamKey,
        autoPublish: autoPublish,
        simultaneousStream: simultaneousStream,
        quality: quality,
      );

      // Store streaming config
      await _streamingPlatformsCollection.doc(id).set({
        ...streamingPlatform.toMap(),
        'hasStreamKey': streamKey != null,
        'hasAccessToken': accessToken != null,
        'connectedAt': DateTime.now().toIso8601String(),
      });

      // Verify connection (simulated)
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status
      await _streamingPlatformsCollection.doc(id).update({
        'status': IntegrationStatus.connected.name,
      });

      final integration = Integration(
        id: id,
        name: streamingPlatform.name,
        type: IntegrationType.streaming,
        status: IntegrationStatus.connected,
        accountId: channelId,
        config: streamingPlatform.toMap(),
        connectedAt: DateTime.now(),
      );

      await _integrationsCollection.doc(id).set(integration.toMap());
      _integrationController.add(integration);

      AnalyticsService.instance.logEvent(
        name: 'streaming_platform_integrated',
        parameters: {
          'platform': platform.name,
          'quality': quality.name,
        },
      );

      debugPrint('✅ [Integrations] Streaming platform connected: ${platform.name}');
      return IntegrationResult(success: true, integration: integration);
    } catch (e) {
      debugPrint('❌ [Integrations] Streaming integration failed: $e');
      return IntegrationResult(success: false, error: e.toString());
    }
  }

  String _getStreamingPlatformName(StreamingPlatformType type) => switch (type) {
        StreamingPlatformType.youtube => 'YouTube Live',
        StreamingPlatformType.twitch => 'Twitch',
        StreamingPlatformType.facebook => 'Facebook Live',
        StreamingPlatformType.instagram => 'Instagram Live',
        StreamingPlatformType.tiktok => 'TikTok LIVE',
        StreamingPlatformType.custom => 'Custom RTMP',
      };

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get all integrations
  Future<List<Integration>> getAllIntegrations({IntegrationType? type}) async {
    Query<Map<String, dynamic>> query = _integrationsCollection;

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Integration.fromMap(doc.data())).toList();
  }

  /// Disconnect an integration
  Future<bool> disconnectIntegration(String integrationId) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'status': IntegrationStatus.disconnected.name,
      });
      return true;
    } catch (e) {
      debugPrint('❌ [Integrations] Disconnect failed: $e');
      return false;
    }
  }

  /// Sync an integration
  Future<bool> syncIntegration(String integrationId) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'lastSyncAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ [Integrations] Sync failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _integrationController.close();
  }
}
