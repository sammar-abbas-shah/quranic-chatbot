part of '../main.dart';

// ---------------------------------------------------------------------------
// Settings screen.
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.tr('confirm')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.app.settings;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _Section(
              title: context.tr('appearance'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    context.tr('chooseTheme'),
                    style: AppTypography.caption(color: context.mutedText),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: DropdownButtonFormField<String>(
                    initialValue: s.themeId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.brightness_auto_outlined,
                              size: 20,
                              color: context.cs.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(context.tr('systemDefault')),
                          ],
                        ),
                      ),
                      for (final t in AppThemeCatalog.all)
                        DropdownMenuItem(
                          value: t.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ThemeSwatchDot(spec: t),
                              const SizedBox(width: 12),
                              Text(context.tr(t.nameKey)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      HapticFeedback.selectionClick();
                      s.setThemeId(v);
                    },
                  ),
                ),
              ],
            ),
            _Section(
              title: context.tr('language'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: LanguageSelector(
                    value: s.languageCode,
                    onChanged: s.setLanguage,
                  ),
                ),
              ],
            ),
            _Section(
              title: context.tr('quranSection'),
              children: [
                ListTile(
                  title: Text(context.tr('arabicFontSize')),
                  subtitle: Slider(
                    min: 20,
                    max: 44,
                    divisions: 12,
                    label: s.arabicFontSize.round().toString(),
                    value: s.arabicFontSize,
                    onChanged: s.setArabicFontSize,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTypography.arabicQuran(
                        size: s.arabicFontSize,
                        color: context.cs.onSurface,
                      ),
                      child: const Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(context.tr('translationLanguage')),
                  trailing: DropdownButton<String>(
                    value: s.translationLanguage,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(context.tr('english')),
                      ),
                      DropdownMenuItem(
                        value: 'ur',
                        child: Text(context.tr('urdu')),
                      ),
                      DropdownMenuItem(
                        value: 'both',
                        child: Text(context.tr('translationBoth')),
                      ),
                    ],
                    onChanged: (v) => s.setTranslationLanguage(v ?? 'en'),
                  ),
                ),
                SwitchListTile(
                  title: Text(context.tr('showArabic')),
                  value: s.showArabic,
                  onChanged: s.setShowArabic,
                ),
                SwitchListTile(
                  title: Text(context.tr('showTranslation')),
                  value: s.showTranslation,
                  onChanged: s.setShowTranslation,
                ),
              ],
            ),
            _Section(
              title: context.tr('audio'),
              children: [
                ListTile(
                  title: Text(context.tr('reciter')),
                  trailing: DropdownButton<String>(
                    value: s.reciter,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final r in SettingsController.reciters)
                        DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    onChanged: (v) => s.setReciter(v ?? s.reciter),
                  ),
                ),
                ListTile(
                  title: Text(context.tr('playbackSpeed')),
                  trailing: DropdownButton<double>(
                    value: s.playbackSpeed,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final v in SettingsController.speeds)
                        DropdownMenuItem(value: v, child: Text('${v}x')),
                    ],
                    onChanged: (v) => s.setPlaybackSpeed(v ?? 1.0),
                  ),
                ),
                SwitchListTile(
                  title: Text(context.tr('autoPlay')),
                  subtitle: Text(context.tr('autoPlaySubtitle')),
                  value: s.autoPlay,
                  onChanged: s.setAutoPlay,
                ),
                const OfflineAudioTile(),
              ],
            ),
            _Section(
              title: context.tr('chatSection'),
              children: [
                ListTile(
                  title: Text(context.tr('responseLanguage')),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LanguageSelector(
                      value: s.responseLanguage,
                      onChanged: s.setResponseLanguage,
                    ),
                  ),
                ),
              ],
            ),
            _Section(
              title: context.tr('account'),
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(context.tr('logOut')),
                  onTap: () async {
                    final settings = context.appRead.settings;
                    final navigator = Navigator.of(context);
                    if (await _confirm(context, context.tr('logOutConfirm'))) {
                      await settings.setLoggedIn(false);
                      navigator.pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (r) => false,
                      );
                    }
                  },
                ),
              ],
            ),
            _Section(
              title: context.tr('privacy'),
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(context.tr('clearChatHistory')),
                  onTap: () async {
                    final history = context.appRead.history;
                    final chat = context.appRead.chat;
                    if (await _confirm(
                      context,
                      context.tr('clearChatConfirm'),
                    )) {
                      await history.clear();
                      chat.newConversation();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: context.cs.error,
                  ),
                  title: Text(
                    context.tr('clearLocalData'),
                    style: TextStyle(color: context.cs.error),
                  ),
                  onTap: () async {
                    final history = context.appRead.history;
                    final chat = context.appRead.chat;
                    final bookmarks = context.appRead.bookmarks;
                    final nav = context.appRead.nav;
                    final navigator = Navigator.of(context);
                    if (await _confirm(
                      context,
                      context.tr('clearDataConfirm'),
                    )) {
                      await history.clear();
                      await bookmarks.clear();
                      chat.newConversation();
                      await s.resetAll();
                      await RecitationCache.instance.clear();
                      nav.go(0);
                      navigator.pushNamedAndRemoveUntil(
                        AppRoutes.splash,
                        (r) => false,
                      );
                    }
                  },
                ),
              ],
            ),
            _Section(
              title: context.tr('aboutSection'),
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(context.tr('aboutApp')),
                  trailing: Icon(context.forwardIcon, size: 18),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Backend connection test'),
                  trailing: Icon(context.forwardIcon, size: 18),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.backendTest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption(color: context.accentGold)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Small two-tone circle previewing a color theme: an outer ring in the
/// theme's background color and an inner dot in its accent color.
class _ThemeSwatchDot extends StatelessWidget {
  const _ThemeSwatchDot({required this.spec});
  final AppThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: spec.swatchBg,
        border: Border.all(color: spec.border, width: 1),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: spec.swatchAccent,
        ),
      ),
    );
  }
}
