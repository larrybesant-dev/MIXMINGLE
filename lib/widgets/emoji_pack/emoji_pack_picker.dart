import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../presentation/providers/user_provider.dart';
import 'emoji_pack_catalog.dart';
import 'emoji_pack_item.dart';

/// Full-featured emoji / GIF picker bottom sheet.
///
/// Usage:
/// ```dart
/// await EmojiPackPicker.show(context, ref,
///   onSelected: (item) => sendMessage(item.messageContent));
/// ```
class EmojiPackPicker {
  EmojiPackPicker._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required void Function(EmojiPackItem item) onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EmojiPackPickerSheet(onSelected: onSelected),
    );
  }
}

// ── Private sheet widget ───────────────────────────────────────────────────

class _EmojiPackPickerSheet extends ConsumerStatefulWidget {
  const _EmojiPackPickerSheet({required this.onSelected});

  final void Function(EmojiPackItem) onSelected;

  @override
  ConsumerState<_EmojiPackPickerSheet> createState() =>
      _EmojiPackPickerSheetState();
}

class _EmojiPackPickerSheetState
    extends ConsumerState<_EmojiPackPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  static const _categories = EmojiCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _categories.length, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adultEnabled =
        ref.watch(userProvider)?.adultModeEnabled ?? false;
    final isSearching = _query.trim().isNotEmpty;

    final sheetHeight = MediaQuery.of(context).size.height * 0.58;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Color(0xFF110D0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0x40D4AF37), width: 1),
          ),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(isSearching),
            if (!isSearching) _buildTabBar(adultEnabled),
            Expanded(
              child: isSearching
                  ? _buildSearchGrid(_query, adultEnabled)
                  : _buildTabViews(adultEnabled),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drag handle ──────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: VelvetNoir.outlineVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  // ── Search row ───────────────────────────────────────────────────────────

  Widget _buildHeader(bool isSearching) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: VelvetNoir.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: VelvetNoir.primary.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: VelvetNoir.onSurface,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search emojis…',
                  hintStyle: const TextStyle(
                    color: VelvetNoir.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: VelvetNoir.onSurfaceVariant,
                    size: 18,
                  ),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 16,
                              color: VelvetNoir.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool adultEnabled) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: VelvetNoir.primary,
      indicatorWeight: 2,
      labelColor: VelvetNoir.primary,
      unselectedLabelColor: VelvetNoir.onSurfaceVariant,
      labelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: _categories.map((cat) {
        final locked = cat.isAdultOnly && !adultEnabled;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat.label),
              if (locked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline, size: 12,
                    color: VelvetNoir.onSurfaceVariant),
              ],
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  // ── TabBarView ───────────────────────────────────────────────────────────

  Widget _buildTabViews(bool adultEnabled) {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((cat) {
        if (cat.isAdultOnly && !adultEnabled) {
          return _buildAgeLock(cat);
        }
        final items = EmojiPackCatalog.byCategory(cat);
        return _buildGrid(items);
      }).toList(growable: false),
    );
  }

  // ── Search results grid ──────────────────────────────────────────────────

  Widget _buildSearchGrid(String query, bool adultEnabled) {
    var results = EmojiPackCatalog.search(query);
    if (!adultEnabled) {
      results = results
          .where((e) => !e.isAdultOnly)
          .toList(growable: false);
    }
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$query"',
          style: const TextStyle(
            color: VelvetNoir.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }
    return _buildGrid(results);
  }

  // ── Core grid ────────────────────────────────────────────────────────────

  Widget _buildGrid(List<EmojiPackItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _EmojiGridCell(item: items[index], onTap: _select),
    );
  }

  // ── Age-lock placeholder ─────────────────────────────────────────────────

  Widget _buildAgeLock(EmojiCategory cat) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VelvetNoir.secondary.withValues(alpha: 0.15),
                border: Border.all(
                  color: VelvetNoir.secondary.withValues(alpha: 0.40),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.lock_outline,
                  color: VelvetNoir.secondaryBright, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              '${cat.label} is 18+',
              style: const TextStyle(
                color: VelvetNoir.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enable adult mode in your profile settings to unlock this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VelvetNoir.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Callback ─────────────────────────────────────────────────────────────

  void _select(EmojiPackItem item) {
    Navigator.of(context).pop();
    widget.onSelected(item);
  }
}

// ── Single grid cell ───────────────────────────────────────────────────────

class _EmojiGridCell extends StatelessWidget {
  const _EmojiGridCell({required this.item, required this.onTap});

  final EmojiPackItem item;
  final void Function(EmojiPackItem) onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.name,
      preferBelow: false,
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: VelvetNoir.outlineVariant.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _buildThumbnail(),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.isAsset) {
      return Image.asset(
        item.path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Fallback(name: item.name),
      );
    }
    // Remote URL (GIF or hosted image)
    return CachedNetworkImage(
      imageUrl: item.path,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: VelvetNoir.primary,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _Fallback(name: item.name),
    );
  }
}

/// Fallback shown when the asset / URL cannot be loaded.
/// Renders the first letter of the item name in a gold circle.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VelvetNoir.surfaceBright,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: VelvetNoir.primary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ── Emoji message renderer ─────────────────────────────────────────────────

/// Renders a chat message body that may be an emoji pack item or plain text.
///
/// Drop this widget wherever `Text(message.content)` is used:
/// ```dart
/// EmojiMessageContent(content: message.content, isOwn: isOwn)
/// ```
class EmojiMessageContent extends StatelessWidget {
  const EmojiMessageContent({
    super.key,
    required this.content,
    required this.isOwn,
  });

  final String content;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    if (!EmojiPackItem.isEmojiContent(content)) {
      return Text(
        content,
        style: TextStyle(
          color: isOwn ? Colors.white : VelvetNoir.onSurface,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final path = EmojiPackItem.extractPath(content);
    final isUrl = path.startsWith('http');

    final image = isUrl
        ? CachedNetworkImage(
            imageUrl: path,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            placeholder: (_, __) => const SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VelvetNoir.primary,
                ),
              ),
            ),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined,
                    color: VelvetNoir.onSurfaceVariant, size: 40),
          )
        : Image.asset(
            path,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported_outlined,
                    color: VelvetNoir.onSurfaceVariant, size: 40),
          );

    return image;
  }
}
