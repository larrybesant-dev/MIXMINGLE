import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/core/responsive/responsive_utils.dart';
import 'package:mix_and_mingle/core/animations/app_animations.dart';
import 'package:mix_and_mingle/providers/all_providers.dart';
import 'package:mix_and_mingle/app_routes.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mix_and_mingle/shared/widgets/skeleton_loaders.dart';

class SpeedDatingDecisionPage extends ConsumerWidget {
  final String partnerId;

  const SpeedDatingDecisionPage({
    super.key,
    required this.partnerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerProfileAsync = ref.watch(userProfileProvider(partnerId));

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Your Decision'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: AsyncValueViewEnhanced(
          value: partnerProfileAsync,
          maxRetries: 3,
          skeleton: SkeletonProfileHeader(),
          screenName: 'SpeedDatingDecisionPage',
          providerName: 'userProfileProvider',
          onRetry: () => ref.invalidate(userProfileProvider(partnerId)),
          data: (partner) {
            if (partner == null) {
              return const Center(child: Text('Partner not found'));
            }

            return SingleChildScrollView(
              padding: Responsive.responsivePadding(context),
              child: Column(
                children: [
                  SizedBox(height: Responsive.responsiveSpacing(context, 32)),

                  // Heart animation
                  AppAnimations.scaleIn(
                    curve: Curves.elasticOut,
                    child: Icon(
                      Icons.favorite,
                      size: Responsive.responsiveIconSize(context, 100),
                      color: const Color(0xFFFF006B),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, 32)),

                  // Title
                  AppAnimations.fadeIn(
                    child: Text(
                      'You liked ${partner.username}!',
                      style: TextStyle(
                        fontSize: Responsive.responsiveFontSize(context, 28),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, 16)),

                  // Subtitle
                  AppAnimations.slideInFromBottom(
                    beginOffset: 20,
                    child: Text(
                      'We\'ll let you know if it\'s a match!',
                      style: TextStyle(
                        fontSize: Responsive.responsiveFontSize(context, 16),
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, 48)),

                  // Partner card
                  AppAnimations.slideInFromBottom(
                    beginOffset: 40,
                    child: Card(
                      child: Padding(
                        padding: Responsive.responsivePadding(context),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: Responsive.responsiveValue(
                                context: context,
                                mobile: 50.0,
                                tablet: 60.0,
                                desktop: 70.0,
                              ),
                              backgroundImage:
                                  partner.profileImageUrl != null ? NetworkImage(partner.profileImageUrl!) : null,
                              child: partner.profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: Responsive.responsiveIconSize(context, 50),
                                    )
                                  : null,
                            ),
                            SizedBox(height: Responsive.responsiveSpacing(context, 16)),
                            Text(
                              partner.username ?? 'User',
                              style: TextStyle(
                                fontSize: Responsive.responsiveFontSize(context, 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (partner.age != null)
                              Text(
                                '${partner.age} years old',
                                style: TextStyle(
                                  fontSize: Responsive.responsiveFontSize(context, 16),
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, 48)),

                  // Action buttons
                  AppAnimations.slideInFromBottom(
                    beginOffset: 60,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(AppRoutes.matches);
                            },
                            icon: const Icon(Icons.favorite),
                            label: const Text('View Matches'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.responsiveSpacing(context, 16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.responsiveSpacing(context, 16)),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Start another speed dating session
                              Navigator.of(context).pushReplacementNamed(AppRoutes.speedDatingLobby);
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Try Again'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.responsiveSpacing(context, 16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.responsiveSpacing(context, 16)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                          },
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
