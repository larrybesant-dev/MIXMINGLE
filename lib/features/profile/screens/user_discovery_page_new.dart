/// User Discovery Page
/// Browse and filter users to connect with
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/models/discovery_filters.dart';

/// User Discovery - Find people to connect with
class UserDiscoveryPage extends ConsumerStatefulWidget {
  const UserDiscoveryPage({super.key});

  @override
  ConsumerState<UserDiscoveryPage> createState() => _UserDiscoveryPageState();
}

class _UserDiscoveryPageState extends ConsumerState<UserDiscoveryPage> {
  DiscoveryFilters _filters = DiscoveryFilters.defaultFilters();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      // Build query based on filters
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: user.id);

      // Apply filters
      if (_filters.genders.isNotEmpty && !_filters.genders.contains('Any')) {
        query = query.where('gender', whereIn: _filters.genders);
      }

      if (_filters.onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      if (_filters.onlyOnline) {
        query = query.where('isOnline', isEqualTo: true);
      }

      // Execute query
      final snapshot = await query.limit(50).get();

      // Filter by age locally (Firestore doesn't support range with other where clauses)
      final users = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((userData) {
        final age = userData['age'] as int?;
        if (age == null) return false;
        return age >= _filters.minAge && age <= _filters.maxAge;
      }).toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('âŒ Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const NeonText(
            'DISCOVER',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFiltersDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_users[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final name = userData['displayName'] as String? ?? 'Unknown';
    final age = userData['age'] as int?;
    final photoUrl = userData['photoUrl'] as String?;
    final isVerified = userData['isVerified'] as bool? ?? false;
    final isOnline = userData['isOnline'] as bool? ?? false;

    return NeonGlowCard(
      glowColor: DesignColors.accent,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: userData['id'],
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: DesignColors.accent.withValues(
                        alpha: 255, red: 255, green: 255, blue: 255),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: DesignColors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                // Online indicator
                if (isOnline)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DesignColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // User info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        age != null ? '$name, $age' : name,
                        style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified)
                      const Icon(
                        Icons.verified,
                        color: DesignColors.gold,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: DesignColors.white
                .withValues(alpha: 255, red: 255, green: 255, blue: 255),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              color: DesignColors.white
                  .withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'RESET FILTERS',
            onPressed: () {
              setState(() {
                _filters = DiscoveryFilters.defaultFilters();
              });
              _loadUsers();
            },
            glowColor: DesignColors.accent,
          ),
        ],
      ),
    );
  }

  Future<void> _showFiltersDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.background,
        title: const Text(
          'Discovery Filters',
          style: TextStyle(color: DesignColors.white),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age range
                Text(
                  'Age: ${_filters.minAge} - ${_filters.maxAge}',
                  style: const TextStyle(color: DesignColors.white),
                ),
                RangeSlider(
                  values: RangeValues(
                    _filters.minAge.toDouble(),
                    _filters.maxAge.toDouble(),
                  ),
                  min: 18,
                  max: 80,
                  divisions: 62,
                  activeColor: DesignColors.accent,
                  onChanged: (values) {
                    setDialogState(() {
                      _filters = _filters.copyWith(
                        minAge: values.start.round(),
                        maxAge: values.end.round(),
                      );
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Gender preferences
                const Text(
                  'Gender',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['male', 'female', 'non-binary', 'other']
                      .map((gender) => FilterChip(
                            label: Text(gender),
                            selected: _filters.genders.contains(gender),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  _filters = _filters.copyWith(
                                    genders: [..._filters.genders, gender],
                                  );
                                } else {
                                  _filters = _filters.copyWith(
                                    genders: _filters.genders
                                        .where((g) => g != gender)
                                        .toList(),
                                  );
                                }
                              });
                            },
                            backgroundColor: DesignColors.accent.withValues(
                                alpha: 255, red: 255, green: 255, blue: 255),
                            selectedColor: DesignColors.accent.withValues(
                                alpha: 255, red: 255, green: 255, blue: 255),
                            checkmarkColor: DesignColors.white,
                            labelStyle:
                                const TextStyle(color: DesignColors.white),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 16),

                // Only verified
                CheckboxListTile(
                  title: const Text(
                    'Verified only',
                    style: TextStyle(color: DesignColors.white),
                  ),
                  value: _filters.onlyVerified,
                  onChanged: (value) {
                    setDialogState(() {
                      _filters =
                          _filters.copyWith(onlyVerified: value ?? false);
                    });
                  },
                  activeColor: DesignColors.accent,
                ),

                // Only online
                CheckboxListTile(
                  title: const Text(
                    'Online now',
                    style: TextStyle(color: DesignColors.white),
                  ),
                  value: _filters.onlyOnline,
                  onChanged: (value) {
                    setDialogState(() {
                      _filters = _filters.copyWith(onlyOnline: value ?? false);
                    });
                  },
                  activeColor: DesignColors.accent,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignColors.accent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
