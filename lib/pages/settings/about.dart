import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

class Credits extends StatefulWidget {
  const Credits({Key? key}) : super(key: key);

  @override
  State<Credits> createState() => _CreditsState();
}

class _CreditsState extends State<Credits> with WidgetsBindingObserver {
  final themeManager = getIt<ThemeManager>();

  static const String supportEmail = 'contact@catchingclouds.de';
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=com.cloudcatcher.mars_launcher';
  static const String marsDevPage =
      'https://play.google.com/store/apps/dev?id=7784376568737667246';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = primary.withValues(alpha: 0.5);
    final bodyPrimary = TEXT_STYLE_ABOUT_BODY.copyWith(height: 1.5, color: primary);
    final bodySecondary = TEXT_STYLE_ABOUT_BODY.copyWith(height: 1.5, color: secondary);

    return GestureDetector(
      onDoubleTap: () => themeManager.toggleTheme(),
      child: Scaffold(
        appBar: defaultTargetPlatform == TargetPlatform.linux
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                iconTheme: IconThemeData(color: primary),
              )
            : null,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mars Launcher', style: TEXT_STYLE_SETTINGS_TITLE),
                  const SizedBox(height: 20),
                  // This app — personal "why", in primary (white).
                  Text(
                    'A few years ago, I read Cal Newport\'s Digital Minimalism and started thinking about how a smartphone could feel calmer and more intentional. I couldn\'t switch to a dumb phone, but I wanted mine to feel that way, so I built the launcher I was missing.',
                    style: bodyPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I\'ve used it every day since then, gradually adapting it to fit my real life. Over time, it evolved into a fast and focused home screen, with small, thoughtful tools and gesture-based interactions that stay out of the way. The goal was never to add more, but to make using my phone feel simpler.',
                    style: bodyPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What started as a personal tool became the phone experience I wanted to share with others. Since it will always be free, perhaps it can make your phone feel a little calmer and more intentional too. :)',
                    style: bodyPrimary,
                  ),

                  const SizedBox(height: 12),

                  // API attribution — belongs to this app's weather feature.
                  Text.rich(TextSpan(
                    style: TEXT_STYLE_ABOUT_BODY.copyWith(fontSize: 13, height: 1.5, color: secondary),
                    children: [
                      const TextSpan(text: 'Weather data by '),
                      TextSpan(
                        text: 'open-meteo',
                        style: TextStyle(color: primary, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => _open('https://open-meteo.com/'),
                      ),
                      const TextSpan(text: ' ('),
                      TextSpan(
                        text: 'license',
                        style: TextStyle(color: primary, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _open('https://github.com/open-meteo/open-meteo/blob/main/LICENSE'),
                      ),
                      const TextSpan(text: ').'),
                    ],
                  )),




                  const SizedBox(height: 16),
                  Text('—', style: TextStyle(fontSize: 15, color: secondary)),
                  const SizedBox(height: 16),


                  // About Mars — shared philosophy, grayed, identical across all apps.
                  Text(
                    'Mars — Minimalist And Really Simple. A growing family of small, calm tools built around one idea: solve one problem well, and never fight for your attention. Created by one person out of passion and conviction. Forever open source. No ads. No tracking.',
                    style: bodySecondary,
                  ),
                  const SizedBox(height: 30),


                  _LinkRow(label: 'More Mars apps', onTap: () => _open(marsDevPage)),
                  _LinkRow(label: 'Get in touch', onTap: () => _open('mailto:$supportEmail?subject=Mars%20Launcher%20feedback')),
                  _LinkRow(label: 'Rate Mars Launcher', onTap: () => _open(storeUrl)),
                  const SizedBox(height: 20),




                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: primary)),
            ),
            Icon(Icons.north_east, size: 18, color: primary.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
