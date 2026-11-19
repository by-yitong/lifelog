import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/app_typography.dart';
import '../data/bangumi.dart';

/// 搜索 Bangumi 动漫封面：输入名字 → 网格出封面 → 点选返回。
/// 返回值为选中的条目；用户直接退出时返回 null。
class BangumiSearchPage extends StatefulWidget {
  final String initialKeyword;

  const BangumiSearchPage({super.key, this.initialKeyword = ''});

  @override
  State<BangumiSearchPage> createState() => _BangumiSearchPageState();
}

class _BangumiSearchPageState extends State<BangumiSearchPage> {
  late final TextEditingController _query =
      TextEditingController(text: widget.initialKeyword);
  final FocusNode _focus = FocusNode();

  List<BangumiSubject>? _results;
  String? _error;
  bool _searching = false;
  String _lastKeyword = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final kw = _query.text.trim();
    if (kw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先输入动漫名字')),
      );
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _lastKeyword = kw;
    });
    try {
      final results = await BangumiApi.searchAnime(kw);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '网络不给力，请检查网络后重试';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Space.lg),
          child: TextField(
            controller: _query,
            focusNode: _focus,
            autofocus: widget.initialKeyword.trim().isEmpty,
            autofillHints: const [],
            maxLength: 40,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: AppTypography.body(color: colors.ink),
            decoration: InputDecoration(
              counterText: '',
              hintText: '动漫名字，如：葬送的芙莉莲',
              prefixIcon: Icon(Icons.search, size: 20, color: colors.inkFaint),
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _searching ? null : _search,
            child: const Text('搜索'),
          ),
        ],
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _CenterHint(
        emoji: '📡',
        title: '搜索失败',
        subtitle: _error!,
        action: FilledButton.tonal(onPressed: _search, child: const Text('重试')),
      );
    }
    final results = _results;
    if (results == null) {
      return const _CenterHint(
        emoji: '🔍',
        title: '输入名字搜封面',
        subtitle: '封面来自 Bangumi（番组计划）',
      );
    }
    if (results.isEmpty) {
      return _CenterHint(
        emoji: '🫥',
        title: '没找到「$_lastKeyword」',
        subtitle: '试试更短的名字，比如只搜主标题',
        action: TextButton(
          onPressed: () {
            _query.clear();
            _focus.requestFocus();
          },
          child: const Text('换个名字'),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl,
          Space.xxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Space.sm,
        mainAxisSpacing: Space.md,
        childAspectRatio: 0.53,
      ),
      itemCount: results.length,
      itemBuilder: (context, i) => _CoverCell(
        subject: results[i],
        onTap: () => Navigator.pop(context, results[i]),
      ),
    );
  }
}

class _CoverCell extends StatelessWidget {
  final BangumiSubject subject;
  final VoidCallback onTap;

  const _CoverCell({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.field),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.field),
              child: Image.network(
                subject.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : ColoredBox(color: colors.surfaceAlt),
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors.surfaceAlt,
                  child: Icon(Icons.broken_image_outlined,
                      size: 28, color: colors.inkFaint),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            subject.name,
            style: AppTypography.caption(color: colors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CenterHint extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? action;

  const _CenterHint({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: Space.lg),
            Text(title, style: AppTypography.headline(color: colors.ink)),
            const SizedBox(height: Space.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: colors.inkSub),
            ),
            if (action != null) ...[
              const SizedBox(height: Space.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
