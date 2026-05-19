import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── STATUS BADGE ──
class StatusBadge extends StatelessWidget {
  final String status;
  final int daysOverdue;
  final int pctPaid;

  const StatusBadge({super.key, required this.status, this.daysOverdue = 0, this.pctPaid = 0});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    switch (status) {
      case 'paid':
        bg = AppColors.greenBg; fg = AppColors.green; label = 'Fully Paid';
        break;
      case 'partial':
        bg = AppColors.yellowBg; fg = AppColors.yellow; label = '$pctPaid% paid';
        break;
      case 'overdue':
        bg = AppColors.accentBg; fg = AppColors.accent; label = 'Overdue ${daysOverdue}d';
        break;
      default:
        bg = AppColors.yellowBg; fg = AppColors.yellow; label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Roboto')),
        ],
      ),
    );
  }
}

// ── STAT CARD ──
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final valueSize = w < 400 ? 18.0 : w < 600 ? 20.0 : 24.0;
    final labelSize = w < 400 ? 8.0 : 9.0;
    final subSize = w < 400 ? 10.0 : 11.0;
    final badgeSize = w < 400 ? 9.0 : 10.0;
    final padding = w < 400 ? 10.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: labelSize,
                color: AppColors.muted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                )),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: subSize,
                color: AppColors.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badgeText,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: badgeSize,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── SECTION HEADER ──
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
        if (action != null) action!,
      ],
    );
  }
}

// ── NOTE BOX ──
class NoteBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final Color border;

  const NoteBox({super.key, required this.text, required this.color, required this.bg, required this.border});

  factory NoteBox.yellow(String text) => NoteBox(text: text, color: AppColors.yellow, bg: AppColors.yellowBg, border: const Color(0x2EB87C00));
  factory NoteBox.green(String text) => NoteBox(text: text, color: AppColors.green, bg: AppColors.greenBg, border: const Color(0x2E1A6B3C));
  factory NoteBox.blue(String text) => NoteBox(text: text, color: AppColors.blue, bg: AppColors.blueBg, border: const Color(0x2E1A4FA0));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: color, height: 1.55)),
    );
  }
}

// ── APP BUTTON ──
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final IconData? icon;
  final bool small;
  final bool outlined;

  const AppButton({super.key, required this.label, this.onTap, this.bg, this.fg, this.icon, this.small = false, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? AppColors.accent;
    final fgColor = fg ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 7 : 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: AppColors.border2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: small ? 13 : 15, color: fgColor), const SizedBox(width: 5)],
            Text(label, style: TextStyle(fontFamily: 'Roboto', fontSize: small ? 12 : 13, fontWeight: FontWeight.w600, color: fgColor)),
          ],
        ),
      ),
    );
  }
}

// ── FORM FIELD ──
class AppField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.ink),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── AVATAR ──
class ClientAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const ClientAvatar({super.key, required this.initials, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.25)),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(fontFamily: 'Roboto', fontSize: size * 0.38, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

// ── AVATAR COLOR ──
Color avatarColor(String name) {
  final colors = [
    AppColors.accent, AppColors.green, AppColors.blue,
    const Color(0xFF7C3AED), const Color(0xFFB45309), const Color(0xFF0E7490),
  ];
  int h = 0;
  for (final c in name.runes) h = c + ((h << 5) - h);
  return colors[h.abs() % colors.length];
}


// ── HOVER EFFECT WRAPPER ──────────────────────────────────
class HoverWidget extends StatefulWidget {
  final Widget child;
  final Widget hoverChild;
  const HoverWidget({super.key, required this.child, required this.hoverChild});
  @override
  State<HoverWidget> createState() => _HoverWidgetState();
}
class _HoverWidgetState extends State<HoverWidget> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _hovered ? widget.hoverChild : widget.child,
    );
  }
}

// ── HOVER BUTTON ─────────────────────────────────────────
class HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color hoverBg;
  final Color fg;
  final Color hoverFg;
  final IconData? icon;
  final bool small;
  final double radius;
  final EdgeInsets? padding;

  const HoverButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = AppColors.accent,
    this.hoverBg = const Color(0xFFC0390D),
    this.fg = Colors.white,
    this.hoverFg = Colors.white,
    this.icon,
    this.small = false,
    this.radius = 8,
    this.padding,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding ?? EdgeInsets.symmetric(
              horizontal: widget.small ? 12 : 16,
              vertical: widget.small ? 7 : 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverBg : widget.bg,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _hovered ? [BoxShadow(
                color: widget.bg.withOpacity(0.35),
                blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.small ? 13 : 15,
                  color: _hovered ? widget.hoverFg : widget.fg),
              const SizedBox(width: 5),
            ],
            Text(widget.label, style: TextStyle(
                fontFamily: 'Syne',
                fontSize: widget.small ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: _hovered ? widget.hoverFg : widget.fg)),
          ]),
        ),
      ),
    );
  }
}

// ── HOVER TEXT LINK ──────────────────────────────────────
class HoverLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color hoverColor;
  final double fontSize;
  final FontWeight fontWeight;

  const HoverLink({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.accent,
    this.hoverColor = const Color(0xFFC0390D),
    this.fontSize = 13,
    this.fontWeight = FontWeight.w700,
  });

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: _hovered ? widget.hoverColor : widget.color,
            decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: widget.hoverColor,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ── HOVER CARD ───────────────────────────────────────────
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
  });
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surface2 : AppColors.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: _hovered ? AppColors.accent.withOpacity(0.3) : AppColors.border),
            boxShadow: _hovered ? [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── HOVER ICON BUTTON ────────────────────────────────────
class HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color hoverColor;
  final Color? hoverBg;
  final double size;
  final String? tooltip;
  const HoverIconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.color = AppColors.muted,
    this.hoverColor = AppColors.accent,
    this.hoverBg,
    this.size = 20,
    this.tooltip,
  });
  @override
  State<HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<HoverIconBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered ? (widget.hoverBg ?? AppColors.accentBg) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon, size: widget.size,
              color: _hovered ? widget.hoverColor : widget.color),
        ),
      ),
    );
    if (widget.tooltip != null) return Tooltip(message: widget.tooltip!, child: btn);
    return btn;
  }
}