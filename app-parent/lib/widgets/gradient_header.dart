import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tab scaffold with a brand-gradient header that bleeds behind the status
/// bar, and a rounded content sheet that holds the scrolling body.
class HeaderShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  const HeaderShell({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C4843), AppColors.brand],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 18),
              child: header,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain white-on-gradient title for header rows.
class HeaderTitle extends StatelessWidget {
  final String text;
  const HeaderTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
