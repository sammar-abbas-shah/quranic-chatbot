part of '../main.dart';

// ---------------------------------------------------------------------------
// About screen.
// ---------------------------------------------------------------------------

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(String titleKey, String bodyKey) => Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(titleKey),
                style: AppTypography.heading(
                    size: 18, color: context.cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(bodyKey),
                style: AppTypography.body(color: context.mutedText),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('aboutApp'))),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeSlideIn(child: const Center(child: AppLogo(size: 88))),
            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr('appName'),
                style: AppTypography.heading(
                  size: 24,
                  color: context.cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${context.tr('version')} 1.0.0',
                style: AppTypography.caption(color: context.mutedText),
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: block('credits', 'creditsText'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: block('sources', 'sourcesText'),
            ),
          ],
        ),
      ),
    );
  }
}
