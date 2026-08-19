import 'package:flutter/material.dart';
import '../constants.dart';
import 'frosted_glass_surface.dart';
import 'pressable_scale.dart';

class LoungeDropdownItem<T> {
  final T? value;
  final String label;
  const LoungeDropdownItem({required this.value, required this.label});
}

/// The app's bespoke dropdown selector: a themed trigger pill that opens a
/// spring-animated frosted popover list -- the single canonical replacement
/// for stock [DropdownButton]/[DropdownButtonFormField] everywhere.
class LoungeDropdown<T> extends StatefulWidget {
  final T? value;
  final List<LoungeDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  /// Highlights the trigger's border/fill when a non-default value is active.
  final bool isActive;

  /// A compact variant (icon-trailing pill, no fill/border) for tight spaces
  /// like the detail screen's inline country selector.
  final bool dense;

  const LoungeDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.isActive = false,
    this.dense = false,
  });

  @override
  State<LoungeDropdown<T>> createState() => _LoungeDropdownState<T>();
}

class _LoungeDropdownState<T> extends State<LoungeDropdown<T>> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  String get _currentLabel {
    final match = widget.items.where((item) => item.value == widget.value);
    if (match.isNotEmpty) return match.first.label;
    return widget.hintText ?? '';
  }

  void _toggle(BuildContext triggerContext) {
    if (_entry != null) {
      _close();
    } else {
      _open(triggerContext);
    }
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _open(BuildContext triggerContext) {
    final renderBox = triggerContext.findRenderObject() as RenderBox;
    final triggerSize = renderBox.size;
    final triggerTopLeft = renderBox.localToGlobal(Offset.zero);
    final ambiance = triggerContext.ambianceColors;
    final overlay = Overlay.of(triggerContext, rootOverlay: true);
    final screenSize = MediaQuery.of(triggerContext).size;

    const popoverWidth = 220.0;
    // Keep the popover fully on-screen: right-align to the trigger when
    // left-aligning would push it past the screen edge (e.g. a compact
    // trigger sitting near the right edge, like the country selector).
    final wantsLeftAligned = triggerTopLeft.dx + popoverWidth <= screenSize.width - 8;
    final left = wantsLeftAligned
        ? triggerTopLeft.dx
        : (triggerTopLeft.dx + triggerSize.width - popoverWidth).clamp(8.0, screenSize.width - popoverWidth - 8);
    final top = triggerTopLeft.dy + triggerSize.height + 6;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Outside-tap barrier.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: popoverWidth < triggerSize.width ? triggerSize.width : popoverWidth,
              child: _LoungePopover(
                items: widget.items,
                selected: widget.value,
                ambiance: ambiance,
                onSelected: (value) {
                  widget.onChanged(value);
                  _close();
                },
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;
    final isOpen = _entry != null;

    return Builder(
        builder: (triggerContext) {
          if (widget.dense) {
            return PressableScale(
              onTap: () => _toggle(triggerContext),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentLabel,
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ambiance.ink,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: ambiance.sub,
                    size: 20,
                  ),
                ],
              ),
            );
          }

          return PressableScale(
            onTap: () => _toggle(triggerContext),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isActive ? ambiance.acc.withValues(alpha: 0.14) : ambiance.pill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isActive ? ambiance.acc : ambiance.lineRgba,
                  width: widget.isActive ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentLabel.isEmpty ? (widget.hintText ?? '') : _currentLabel,
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        color: _currentLabel.isEmpty ? ambiance.sub : ambiance.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: ambiance.sub,
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}

class _LoungePopover<T> extends StatefulWidget {
  final List<LoungeDropdownItem<T>> items;
  final T? selected;
  final AmbianceColors ambiance;
  final ValueChanged<T?> onSelected;

  const _LoungePopover({
    required this.items,
    required this.selected,
    required this.ambiance,
    required this.onSelected,
  });

  @override
  State<_LoungePopover<T>> createState() => _LoungePopoverState<T>();
}

class _LoungePopoverState<T> extends State<_LoungePopover<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppPhysics.houseSpringDuration);
    _curved = CurvedAnimation(parent: _controller, curve: AppPhysics.houseSpringCurve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = widget.ambiance;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topLeft,
        child: FadeTransition(
          opacity: _curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(_curved),
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: FrostedGlassSurface(
                borderRadius: 14,
                backgroundColor: ambiance.card2.withValues(alpha: 0.92),
                borderColor: ambiance.acc.withValues(alpha: 0.35),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = item.value == widget.selected;
                    return PressableScale(
                      onTap: () => widget.onSelected(item.value),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: isSelected ? ambiance.acc.withValues(alpha: 0.12) : Colors.transparent,
                        child: Text(
                          item.label,
                          style: AppThemes.safeGeist(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? ambiance.acc : ambiance.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
