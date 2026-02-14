import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/core/responsive/responsive_utils.dart';
import 'package:mix_and_mingle/core/animations/app_animations.dart';
import 'package:mix_and_mingle/providers/all_providers.dart';
import 'package:mix_and_mingle/app_routes.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/widgets/loading_widgets.dart';
import 'package:mix_and_mingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mix_and_mingle/shared/widgets/skeleton_loaders.dart';
import 'package:mix_and_mingle/shared/models/speed_dating.dart';

class SpeedDatingLobbyPage extends ConsumerStatefulWidget {
  const SpeedDatingLobbyPage({super.key});

  @override
  ConsumerState<SpeedDatingLobbyPage> createState() => _SpeedDatingLobbyPageState();
}

class _SpeedDatingLobbyPageState extends ConsumerState<SpeedDatingLobbyPage> {
  @override
  void initState() {
    super.initState();
    // Join lobby on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedDatingControllerProvider.notifier).joinLobby();
    });
  }

  @override
  void dispose() {
    // Leave lobby on dispose
    ref.read(speedDatingControllerProvider.notifier).leaveLobby();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(activeSpeedDatingSessionProvider);
    final timerState = ref.watch(speedDatingTimerProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Speed Dating Lobby'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: AsyncValueViewEnhanced(
          value: sessionAsync,
          maxRetries: 3,
          skeleton: SkeletonCard(),
          screenName: 'SpeedDatingLobbyPage',
          providerName: 'activeSpeedDatingSessionProvider',
          onRetry: () => ref.invalidate(activeSpeedDatingSessionProvider),
          data: (session) {
            if (session == null) {
              return _buildWaitingState(context);
            }

            // Session is active
            if (session.status == SpeedDatingStatus.active || session.status == SpeedDatingStatus.inProgress) {
              return _buildActiveSession(context, ref, session, timerState.inMinutes);
            }

            // Session completed
            if (session.status == SpeedDatingStatus.completed) {
              return _buildCompletedState(context);
            }

            return _buildWaitingState(context);
          },
        ),
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAnimations.pulse(
              child: Icon(
                Icons.favorite,
                size: Responsive.responsiveIconSize(context, 100),
                color: const Color(0xFFFF006B),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 32)),
            Text(
              'Finding your match...',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 16)),
            Text(
              'We\'re matching you with someone special',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 16),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 48)),
            const CircularProgressIndicator(),
            SizedBox(height: Responsive.responsiveSpacing(context, 24)),
            Text(
              'This usually takes less than 30 seconds',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 14),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession(
    BuildContext context,
    WidgetRef ref,
    SpeedDatingSession session,
    int timerSeconds,
  ) {
    final partnerId = session.participants.firstWhere((id) => id != ref.read(currentUserProvider).value?.id);
    final partnerProfileAsync = ref.watch(userProfileProvider(partnerId));

    return partnerProfileAsync.when(
      data: (partner) {
        if (partner == null) {
          return const Center(child: Text('Partner not found'));
        }

        return SingleChildScrollView(
          padding: Responsive.responsivePadding(context),
          child: Column(
            children: [
              // Timer
              AppAnimations.scaleIn(
                child: _buildTimer(context, timerSeconds),
              ),
              SizedBox(height: Responsive.responsiveSpacing(context, 32)),

              // Partner info
              AppAnimations.fadeIn(
                child: _buildPartnerCard(context, partner),
              ),
              SizedBox(height: Responsive.responsiveSpacing(context, 32)),

              // Conversation starters
              _buildConversationStarters(context),
              SizedBox(height: Responsive.responsiveSpacing(context, 32)),

              // Decision buttons (if time is up)
              if (timerSeconds == 0) _buildDecisionButtons(context, partnerId),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingSpinner()),
      error: (_, __) => const Center(child: Text('Error loading partner')),
    );
  }

  Widget _buildTimer(BuildContext context, int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final displayTime = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(Responsive.responsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF006B), Color(0xFFFFB800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006B).withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Text(
        displayTime,
        style: TextStyle(
          fontSize: Responsive.responsiveFontSize(context, 48),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, dynamic partner) {
    return Card(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          children: [
            // Profile image
            CircleAvatar(
              radius: Responsive.responsiveValue(
                context: context,
                mobile: 60.0,
                tablet: 80.0,
                desktop: 100.0,
              ),
              backgroundImage: partner.profileImageUrl != null ? NetworkImage(partner.profileImageUrl!) : null,
              child: partner.profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: Responsive.responsiveIconSize(context, 60),
                    )
                  : null,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 16)),

            // Name
            Text(
              partner.username,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 8)),

            // Age & Location
            Text(
              '${partner.age ?? 'Age not specified'} • ${partner.location ?? 'Location not specified'}',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 16),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 16)),

            // Bio
            if (partner.bio != null)
              Text(
                partner.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.responsiveFontSize(context, 14),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            SizedBox(height: Responsive.responsiveSpacing(context, 16)),

            // Interests
            if (partner.interests != null && partner.interests!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: partner.interests!.take(5).map<Widget>((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationStarters(BuildContext context) {
    final starters = [
      'What do you like to do for fun?',
      'What\'s your favorite place to travel?',
      'What kind of music are you into?',
      'What\'s your dream job?',
      'Do you have any pets?',
    ];

    return Card(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Starters',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 12)),
            ...starters.map((starter) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: Responsive.responsiveIconSize(context, 16),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        starter,
                        style: TextStyle(
                          fontSize: Responsive.responsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButtons(BuildContext context, String partnerId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(speedDatingControllerProvider.notifier).submitDecision(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: EdgeInsets.symmetric(
                vertical: Responsive.responsiveSpacing(context, 16),
              ),
            ),
            icon: const Icon(Icons.close),
            label: const Text('Pass'),
          ),
        ),
        SizedBox(width: Responsive.responsiveSpacing(context, 16)),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(speedDatingControllerProvider.notifier).submitDecision(true);
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.speedDatingDecision,
                arguments: partnerId,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.responsiveSpacing(context, 16),
              ),
            ),
            icon: const Icon(Icons.favorite),
            label: const Text('Like'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: Responsive.responsiveIconSize(context, 100),
              color: Colors.green,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 24)),
            Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 16)),
            Text(
              'Check your matches to see if it\'s a match!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 16),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 32)),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.matches);
              },
              child: const Text('View Matches'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Speed Dating Works'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. You\'ll be matched with someone randomly'),
              const SizedBox(height: 8),
              const Text('2. You have 3 minutes to chat'),
              const SizedBox(height: 8),
              const Text('3. Decide if you like them'),
              const SizedBox(height: 8),
              const Text('4. If they like you too, it\'s a match!'),
              const SizedBox(height: 16),
              Text(
                'Be respectful and have fun!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
