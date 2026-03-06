import 'package:flutter/material.dart';

class PriseMesureOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final String? badge;
  final VoidCallback onTap;

  const PriseMesureOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.onTap,
    this.badge,
  });
}

class PriseMesureModelView extends StatelessWidget {
  final String description;
  final List<PriseMesureOption> options;

  const PriseMesureModelView({
    super.key,
    required this.description,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: options.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          );
        }

        final option = options[index - 1];
        return _PriseMesureOptionCard(option: option);
      },
    );
  }
}

class _PriseMesureOptionCard extends StatelessWidget {
  final PriseMesureOption option;

  const _PriseMesureOptionCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        option.isEnabled ? const Color(0xFFF4A000) : const Color(0xFFD6D6D6);
    final cardColor = option.isEnabled ? Colors.white : const Color(0xFFEFEFEF);
    final iconColor =
        option.isEnabled ? const Color(0xFFF4A000) : const Color(0xFFAEAEAE);
    final titleColor =
        option.isEnabled ? const Color(0xFF1F1F1F) : const Color(0xFF9B9B9B);

    return InkWell(
      onTap: option.isEnabled ? option.onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: option.isEnabled
                    ? const Color(0xFFFFF5DF)
                    : const Color(0xFFDCDCDC),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (option.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4B3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            option.badge!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF4A000),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: option.isEnabled
                          ? const Color(0xFF767676)
                          : const Color(0xFFA5A5A5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: iconColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
