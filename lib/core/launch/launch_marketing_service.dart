/// Launch Marketing Service
///
/// Generates press kits, launch notes, store descriptions,
/// and creator onboarding guides for public launch.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing launch marketing materials
class LaunchMarketingService {
  static LaunchMarketingService? _instance;
  static LaunchMarketingService get instance =>
      _instance ??= LaunchMarketingService._();

  LaunchMarketingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Collections
  static const String _marketingCollection = 'launch_marketing';
  static const String _pressKitCollection = 'press_kits';

  // ============================================================
  // PRESS KIT GENERATION
  // ============================================================

  /// Generate press kit for media distribution
  Future<PressKit> generatePressKit({
    required String version,
    String? customDescription,
  }) async {
    debugPrint('ðŸ“° [Marketing] Generating press kit...');

    try {
      // Get app info
      final appInfo = await _getAppInfo();

      // Get key statistics
      final stats = await _getAppStats();

      // Get featured creators
      final creators = await _getFeaturedCreators();

      // Get high-res assets
      final assets = await _getMarketingAssets();

      final pressKit = PressKit(
        id: 'pk_${DateTime.now().millisecondsSinceEpoch}',
        version: version,
        generatedAt: DateTime.now(),
        appName: appInfo['name'] ?? 'MixMingle',
        tagline: appInfo['tagline'] ?? 'Connect Through Live Video',
        description: customDescription ?? appInfo['description'] ?? '',
        keyFeatures: _getKeyFeatures(),
        statistics: stats,
        featuredCreators: creators,
        assets: assets,
        contactInfo: _getContactInfo(),
        socialLinks: _getSocialLinks(),
      );

      // Save press kit
      await _firestore.collection(_pressKitCollection).doc(pressKit.id).set({
        ...pressKit.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'press_kit_generated',
        parameters: {
          'version': version,
          'kit_id': pressKit.id,
        },
      );

      debugPrint('âœ… [Marketing] Press kit generated: ${pressKit.id}');

      return pressKit;
    } catch (e) {
      debugPrint('âŒ [Marketing] Failed to generate press kit: $e');
      rethrow;
    }
  }

  // ============================================================
  // LAUNCH NOTES
  // ============================================================

  /// Generate launch notes for release
  Future<LaunchNotes> generateLaunchNotes({
    required String version,
    required List<String> highlights,
    List<String>? bugFixes,
    List<String>? knownIssues,
  }) async {
    debugPrint('ðŸ“ [Marketing] Generating launch notes...');

    try {
      final notes = LaunchNotes(
        id: 'ln_${DateTime.now().millisecondsSinceEpoch}',
        version: version,
        generatedAt: DateTime.now(),
        headline: 'MixMingle $version - Now Available!',
        highlights: highlights,
        bugFixes: bugFixes ?? [],
        knownIssues: knownIssues ?? [],
        whatsnew: _generateWhatsNew(highlights),
      );

      // Save launch notes
      await _firestore.collection(_marketingCollection).doc('launch_notes_$version').set({
        ...notes.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'launch_notes_generated',
        parameters: {
          'version': version,
        },
      );

      debugPrint('âœ… [Marketing] Launch notes generated');

      return notes;
    } catch (e) {
      debugPrint('âŒ [Marketing] Failed to generate launch notes: $e');
      rethrow;
    }
  }

  // ============================================================
  // STORE DESCRIPTIONS
  // ============================================================

  /// Generate optimized store descriptions
  Future<StoreDescriptions> generateStoreDescriptions({
    String? customTitle,
    String? customSubtitle,
  }) async {
    debugPrint('ðŸª [Marketing] Generating store descriptions...');

    try {
      final descriptions = StoreDescriptions(
        id: 'sd_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        appStore: AppStoreDescription(
          title: customTitle ?? 'MixMingle - Live Video Chat',
          subtitle: customSubtitle ?? 'Meet New People, Go Live',
          description: _generateAppStoreDescription(),
          keywords: _getAppStoreKeywords(),
          promotionalText: 'Join millions connecting through live video!',
          whatsNew: 'Bug fixes and performance improvements.',
        ),
        playStore: PlayStoreDescription(
          title: customTitle ?? 'MixMingle: Live Video Chat & Meet',
          shortDescription: 'Meet new people, chat live, and build connections',
          fullDescription: _generatePlayStoreDescription(),
          tags: _getPlayStoreTags(),
        ),
      );

      // Save descriptions
      await _firestore.collection(_marketingCollection).doc(descriptions.id).set({
        ...descriptions.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(name: 'store_descriptions_generated');

      debugPrint('âœ… [Marketing] Store descriptions generated');

      return descriptions;
    } catch (e) {
      debugPrint('âŒ [Marketing] Failed to generate store descriptions: $e');
      rethrow;
    }
  }

  // ============================================================
  // CREATOR ONBOARDING GUIDE
  // ============================================================

  /// Generate creator onboarding guide
  Future<CreatorGuide> generateCreatorOnboardingGuide() async {
    debugPrint('ðŸ‘¤ [Marketing] Generating creator onboarding guide...');

    try {
      final guide = CreatorGuide(
        id: 'cg_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        title: 'Welcome to MixMingle Creator Program',
        introduction: _getCreatorIntroduction(),
        gettingStarted: _getGettingStartedSteps(),
        bestPractices: _getCreatorBestPractices(),
        monetization: _getMonetizationInfo(),
        communityGuidelines: _getCommunityGuidelines(),
        support: _getSupportInfo(),
        faq: _getCreatorFAQ(),
      );

      // Save guide
      await _firestore.collection(_marketingCollection).doc(guide.id).set({
        ...guide.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(name: 'creator_guide_generated');

      debugPrint('âœ… [Marketing] Creator guide generated');

      return guide;
    } catch (e) {
      debugPrint('âŒ [Marketing] Failed to generate creator guide: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      final doc = await _firestore.collection('app_config').doc('info').get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, int>> _getAppStats() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final roomsCount = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      final creatorsCount = await _firestore
          .collection('users')
          .where('isCreator', isEqualTo: true)
          .count()
          .get();

      return {
        'totalUsers': usersCount.count ?? 0,
        'activeRooms': roomsCount.count ?? 0,
        'verifiedCreators': creatorsCount.count ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  Future<List<String>> _getFeaturedCreators() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('isCreator', isEqualTo: true)
          .where('featured', isEqualTo: true)
          .limit(5)
          .get();

      return query.docs.map((doc) => doc.data()['displayName'] as String? ?? 'Anonymous').toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getMarketingAssets() async {
    // In production, these would be actual URLs
    return [
      'https://storage.mixmingle.com/press/logo.png',
      'https://storage.mixmingle.com/press/icon.png',
      'https://storage.mixmingle.com/press/screenshot_1.png',
      'https://storage.mixmingle.com/press/screenshot_2.png',
      'https://storage.mixmingle.com/press/screenshot_3.png',
      'https://storage.mixmingle.com/press/promo_video.mp4',
    ];
  }

  List<String> _getKeyFeatures() => [
    'Live video rooms with up to 8 participants',
    'Match with people who share your interests',
    'VIP membership with exclusive perks',
    'Safe and moderated community',
    'Creator program with monetization',
    'Real-time chat and gifting',
  ];

  Map<String, String> _getContactInfo() => {
    'press': 'press@mixmingle.com',
    'partnerships': 'partnerships@mixmingle.com',
    'support': 'support@mixmingle.com',
  };

  Map<String, String> _getSocialLinks() => {
    'twitter': 'https://twitter.com/mixmingle',
    'instagram': 'https://instagram.com/mixmingle',
    'tiktok': 'https://tiktok.com/@mixmingle',
    'discord': 'https://discord.gg/mixmingle',
  };

  String _generateWhatsNew(List<String> highlights) {
    return highlights.map((h) => 'â€¢ $h').join('\n');
  }

  String _generateAppStoreDescription() => '''
Meet new people and make real connections with MixMingle, the live video chat app that brings people together!

ðŸŽ¥ LIVE VIDEO CHAT
Jump into video rooms and meet interesting people from around the world. No swiping required - just real conversations!

ðŸ¤ SMART MATCHING
Our intelligent matching system connects you with people who share your interests. Find your community and build lasting friendships.

â­ VIP EXPERIENCE
Unlock exclusive features with VIP membership:
â€¢ Priority matching
â€¢ Exclusive badges
â€¢ Enhanced profiles
â€¢ Ad-free experience

ðŸŽ¨ BECOME A CREATOR
Build your audience, go live, and earn through gifts and tips. Join thousands of creators already on MixMingle!

ðŸ›¡ï¸ SAFE & MODERATED
Your safety is our priority. We have 24/7 moderation, reporting tools, and community guidelines to keep MixMingle a positive place.

Download MixMingle today and start making genuine connections!
''';

  List<String> _getAppStoreKeywords() => [
    'live video',
    'chat',
    'social',
    'meet people',
    'friends',
    'video call',
    'streaming',
    'community',
    'dating',
    'connection',
  ];

  String _generatePlayStoreDescription() => '''
MixMingle: Where Real Connections Happen

Looking for genuine conversations and meaningful connections? MixMingle is the live video chat app that makes meeting new people fun, easy, and safe.

ðŸ”¥ WHY MIXMINGLE?

âœ¨ Live Video Rooms
Skip the endless swiping! Jump directly into live video conversations with interesting people. Create rooms for any topic - hobbies, music, gaming, or just casual chat.

ðŸ’« Smart Match Technology
Our AI-powered matching connects you with compatible people based on your interests, making every conversation count.

ðŸŽ Interactive Features
â€¢ Send virtual gifts during streams
â€¢ React with fun emojis
â€¢ Chat while watching
â€¢ Join as viewer or participant

ðŸ† VIP Perks
Go VIP for the ultimate experience:
- Stand out with exclusive badges
- Get priority in matching
- Unlock premium features
- Ad-free browsing

ðŸŽ¬ Creator Program
Got personality? Build your following on MixMingle! Go live, engage your audience, and earn real rewards through our creator monetization program.

ðŸ›¡ï¸ Safe Community
We take safety seriously:
- 24/7 active moderation
- One-tap reporting
- Verified profiles available
- Strict community guidelines

ðŸ“² FEATURES

â€¢ HD video chat
â€¢ Interest-based matching
â€¢ Virtual gifts & economy
â€¢ Real-time chat
â€¢ Creator tools
â€¢ Profile customization
â€¢ Activity tracking
â€¢ Weekly challenges

Join millions of users making real connections on MixMingle. Download now and start chatting!

Questions? Contact support@mixmingle.com
''';

  List<String> _getPlayStoreTags() => [
    'Social',
    'Video Chat',
    'Live Streaming',
    'Meet People',
    'Dating',
  ];

  String _getCreatorIntroduction() => '''
Welcome to the MixMingle Creator Program!

As a creator, you'll have access to powerful tools to build your audience, engage your community, and earn real rewards. This guide will help you get started and succeed on our platform.
''';

  List<CreatorStep> _getGettingStartedSteps() => [
    CreatorStep(
      step: 1,
      title: 'Set Up Your Profile',
      description: 'Add a great profile photo, write an engaging bio, and list your interests.',
    ),
    CreatorStep(
      step: 2,
      title: 'Apply for Creator Status',
      description: 'Go to Settings > Creator Program and submit your application.',
    ),
    CreatorStep(
      step: 3,
      title: 'Plan Your Content',
      description: 'Decide on your niche and create a content schedule.',
    ),
    CreatorStep(
      step: 4,
      title: 'Go Live!',
      description: 'Start streaming and engage with your audience.',
    ),
    CreatorStep(
      step: 5,
      title: 'Grow & Monetize',
      description: 'Build your following and start earning through gifts.',
    ),
  ];

  List<String> _getCreatorBestPractices() => [
    'Be consistent - stream at regular times so viewers know when to find you',
    'Engage with your chat - respond to comments and make viewers feel seen',
    'Quality matters - good lighting and audio make a big difference',
    'Be authentic - your unique personality is your biggest asset',
    'Collaborate - partner with other creators to grow together',
    'Stay positive - create a welcoming environment for all viewers',
  ];

  MonetizationInfo _getMonetizationInfo() => MonetizationInfo(
    requirements: [
      'Creator status approved',
      'At least 100 followers',
      'Identity verified',
      'Account in good standing',
    ],
    earningMethods: [
      'Virtual gifts from viewers',
      'Premium subscription tiers',
      'Exclusive content access',
      'Special event hosting',
    ],
    payoutInfo: 'Earnings are paid weekly via PayPal or bank transfer. Minimum payout is \$50.',
  );

  String _getCommunityGuidelines() => '''
As a creator, you're a role model for our community. Please follow these guidelines:

â€¢ Be respectful to all viewers regardless of background
â€¢ No harassment, bullying, or hate speech
â€¢ Keep content appropriate for all ages (no adult content)
â€¢ No spam, scams, or misleading content
â€¢ Protect viewer privacy
â€¢ Report violations you witness

Violations may result in warnings, suspensions, or permanent bans.
''';

  SupportInfo _getSupportInfo() => SupportInfo(
    email: 'creators@mixmingle.com',
    helpCenter: 'https://help.mixmingle.com/creators',
    discord: 'https://discord.gg/mixmingle-creators',
    responseTime: '24-48 hours',
  );

  List<FAQItem> _getCreatorFAQ() => [
    FAQItem(
      question: 'How do I get approved as a creator?',
      answer: 'Submit your application through the app. We review applications within 7 days.',
    ),
    FAQItem(
      question: 'How much can I earn?',
      answer: 'Earnings vary based on your audience size and engagement. Top creators earn \$1000+ monthly.',
    ),
    FAQItem(
      question: 'When do I get paid?',
      answer: 'Payments are processed every Monday for the previous week\'s earnings.',
    ),
    FAQItem(
      question: 'Can I stream from my computer?',
      answer: 'Currently MixMingle is mobile-only, but desktop support is coming soon!',
    ),
    FAQItem(
      question: 'What equipment do I need?',
      answer: 'Just your phone! For best quality, use good lighting and a quiet environment.',
    ),
  ];
}

// ============================================================
// DATA CLASSES
// ============================================================

class PressKit {
  final String id;
  final String version;
  final DateTime generatedAt;
  final String appName;
  final String tagline;
  final String description;
  final List<String> keyFeatures;
  final Map<String, int> statistics;
  final List<String> featuredCreators;
  final List<String> assets;
  final Map<String, String> contactInfo;
  final Map<String, String> socialLinks;

  const PressKit({
    required this.id,
    required this.version,
    required this.generatedAt,
    required this.appName,
    required this.tagline,
    required this.description,
    required this.keyFeatures,
    required this.statistics,
    required this.featuredCreators,
    required this.assets,
    required this.contactInfo,
    required this.socialLinks,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'version': version,
    'generatedAt': generatedAt.toIso8601String(),
    'appName': appName,
    'tagline': tagline,
    'description': description,
    'keyFeatures': keyFeatures,
    'statistics': statistics,
    'featuredCreators': featuredCreators,
    'assets': assets,
    'contactInfo': contactInfo,
    'socialLinks': socialLinks,
  };
}

class LaunchNotes {
  final String id;
  final String version;
  final DateTime generatedAt;
  final String headline;
  final List<String> highlights;
  final List<String> bugFixes;
  final List<String> knownIssues;
  final String whatsnew;

  const LaunchNotes({
    required this.id,
    required this.version,
    required this.generatedAt,
    required this.headline,
    required this.highlights,
    required this.bugFixes,
    required this.knownIssues,
    required this.whatsnew,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'version': version,
    'generatedAt': generatedAt.toIso8601String(),
    'headline': headline,
    'highlights': highlights,
    'bugFixes': bugFixes,
    'knownIssues': knownIssues,
    'whatsnew': whatsnew,
  };
}

class StoreDescriptions {
  final String id;
  final DateTime generatedAt;
  final AppStoreDescription appStore;
  final PlayStoreDescription playStore;

  const StoreDescriptions({
    required this.id,
    required this.generatedAt,
    required this.appStore,
    required this.playStore,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'generatedAt': generatedAt.toIso8601String(),
    'appStore': appStore.toMap(),
    'playStore': playStore.toMap(),
  };
}

class AppStoreDescription {
  final String title;
  final String subtitle;
  final String description;
  final List<String> keywords;
  final String promotionalText;
  final String whatsNew;

  const AppStoreDescription({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.keywords,
    required this.promotionalText,
    required this.whatsNew,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'keywords': keywords,
    'promotionalText': promotionalText,
    'whatsNew': whatsNew,
  };
}

class PlayStoreDescription {
  final String title;
  final String shortDescription;
  final String fullDescription;
  final List<String> tags;

  const PlayStoreDescription({
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.tags,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'shortDescription': shortDescription,
    'fullDescription': fullDescription,
    'tags': tags,
  };
}

class CreatorGuide {
  final String id;
  final DateTime generatedAt;
  final String title;
  final String introduction;
  final List<CreatorStep> gettingStarted;
  final List<String> bestPractices;
  final MonetizationInfo monetization;
  final String communityGuidelines;
  final SupportInfo support;
  final List<FAQItem> faq;

  const CreatorGuide({
    required this.id,
    required this.generatedAt,
    required this.title,
    required this.introduction,
    required this.gettingStarted,
    required this.bestPractices,
    required this.monetization,
    required this.communityGuidelines,
    required this.support,
    required this.faq,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'generatedAt': generatedAt.toIso8601String(),
    'title': title,
    'introduction': introduction,
    'gettingStarted': gettingStarted.map((s) => s.toMap()).toList(),
    'bestPractices': bestPractices,
    'monetization': monetization.toMap(),
    'communityGuidelines': communityGuidelines,
    'support': support.toMap(),
    'faq': faq.map((f) => f.toMap()).toList(),
  };
}

class CreatorStep {
  final int step;
  final String title;
  final String description;

  const CreatorStep({
    required this.step,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'step': step,
    'title': title,
    'description': description,
  };
}

class MonetizationInfo {
  final List<String> requirements;
  final List<String> earningMethods;
  final String payoutInfo;

  const MonetizationInfo({
    required this.requirements,
    required this.earningMethods,
    required this.payoutInfo,
  });

  Map<String, dynamic> toMap() => {
    'requirements': requirements,
    'earningMethods': earningMethods,
    'payoutInfo': payoutInfo,
  };
}

class SupportInfo {
  final String email;
  final String helpCenter;
  final String discord;
  final String responseTime;

  const SupportInfo({
    required this.email,
    required this.helpCenter,
    required this.discord,
    required this.responseTime,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'helpCenter': helpCenter,
    'discord': discord,
    'responseTime': responseTime,
  };
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() => {
    'question': question,
    'answer': answer,
  };
}
