import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sim_card.dart';

/// Styled slider with label and value display, matching the HTML design.
class SimSlider extends StatelessWidget {
  final String label;
  final String value;
  final double min;
  final double max;
  final double current;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? note;
  final Widget? tooltip;

  const SimSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.current,
    this.divisions,
    required this.onChanged,
    this.note,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    if (tooltip != null) ...[const SizedBox(width: 6), tooltip!],
                  ],
                ),
              ),
              EditableTextValue(
                displayValue: value,
                current: current,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: Theme.of(context).sliderTheme,
            child: Slider(
              value: current.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              semanticFormatterCallback: (v) => value,
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(note!, style: const TextStyle(fontSize: 12.5, color: SimColors.muted, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

class EditableTextValue extends StatefulWidget {
  final String displayValue;
  final double current;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const EditableTextValue({
    super.key,
    required this.displayValue,
    required this.current,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<EditableTextValue> createState() => _EditableTextValueState();
}

class _EditableTextValueState extends State<EditableTextValue> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current.toStringAsFixed(widget.current == widget.current.truncateToDouble() ? 0 : 2));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submit();
      }
    });
  }
  
  @override
  void didUpdateWidget(EditableTextValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.current != widget.current) {
      _controller.text = widget.current.toStringAsFixed(widget.current == widget.current.truncateToDouble() ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _isEditing = false);
    final val = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (val != null) {
      widget.onChanged(val.clamp(widget.min, widget.max));
    } else {
      _controller.text = widget.current.toStringAsFixed(widget.current == widget.current.truncateToDouble() ? 0 : 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 100,
        height: 24,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: numStyle(color: SimColors.brass, size: 16),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: SimColors.brassLight.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.displayValue, style: numStyle(color: SimColors.brass)),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: SimColors.brassLight),
          ],
        ),
      ),
    );
  }
}

/// A switch with a label and an optional note
class SimSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? note;

  const SimSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: SimColors.brassLight,
                activeTrackColor: SimColors.brassLight.withAlpha(50),
                inactiveThumbColor: SimColors.heroSub,
                inactiveTrackColor: SimColors.paper2,
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: const TextStyle(fontSize: 12.5, color: SimColors.muted, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

/// Mode toggle button bar (Bourso/Privée, Credit/LOA).
class ModeToggle extends StatelessWidget {
  final List<ModeOption> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const ModeToggle({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: SimColors.card,
        border: Border.all(color: SimColors.line),
        borderRadius: BorderRadius.circular(SimTheme.radius),
        boxShadow: [BoxShadow(color: SimColors.ink.withAlpha(50), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? SimColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        options[i].title,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: isActive ? SimColors.heroText : SimColors.text),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        options[i].subtitle,
                        style: TextStyle(fontSize: 12.5, color: isActive ? SimColors.resultSub : SimColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ModeOption {
  final String title;
  final String subtitle;
  const ModeOption({required this.title, required this.subtitle});
}

/// Usure gauge (TAEG vs taux d'usure).
class UsureGauge extends StatelessWidget {
  final double taeg;
  final double cap;

  const UsureGauge({super.key, required this.taeg, required this.cap});

  @override
  Widget build(BuildContext context) {
    final scaleMax = [cap * 1.3, taeg * 1.05, 1.0].reduce((a, b) => a > b ? a : b);
    final taegPct = (taeg / scaleMax * 100).clamp(0.0, 100.0);
    final capPct = (cap / scaleMax * 100).clamp(0.0, 100.0);
    final over = taeg > cap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: SimColors.paper2,
                      border: Border.all(color: SimColors.line),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: taegPct / 100,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: over ? SimColors.danger : (taeg > cap * 0.9 ? SimColors.warn : SimColors.safe),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Cap marker
                  Positioned(
                    left: capPct / 100 * constraints.maxWidth - 1,
                    top: -3,
                    child: Container(width: 2, height: 16, color: SimColors.ink),
                  ),
                ],
              ),
            );
          }
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 %', style: numStyle(size: 11, color: SimColors.muted)),
            Text('Plafond ${cap.toStringAsFixed(2).replaceAll('.', ',')} %', style: numStyle(size: 11, color: SimColors.muted)),
            Text('${scaleMax.toStringAsFixed(1).replaceAll('.', ',')} %', style: numStyle(size: 11, color: SimColors.muted)),
          ],
        ),
      ],
    );
  }
}

/// A shared selectable chip.
class SimChip extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const SimChip({super.key, required this.label, required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: checked ? SimColors.ink.withAlpha(10) : Colors.white,
          border: Border.all(color: checked ? SimColors.ink : SimColors.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: SimColors.ink),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
        ]),
      ),
    );
  }
}

/// Glossary card with term definitions.
class GlossaryCard extends StatelessWidget {
  final List<GlossaryItem> items;

  const GlossaryCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SimCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Comprendre les termes'),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.term, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(item.definition, style: const TextStyle(fontSize: 13, color: SimColors.muted, height: 1.55)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class GlossaryItem {
  final String term;
  final String definition;
  const GlossaryItem({required this.term, required this.definition});
}

/// Info tooltip button.
class InfoTooltip extends StatelessWidget {
  final String message;
  const InfoTooltip({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SimColors.ink,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      textStyle: const TextStyle(fontSize: 12.5, color: SimColors.heroText, height: 1.5, fontFamily: 'Inter'),
      child: Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SimColors.muted),
        ),
        alignment: Alignment.center,
        child: const Text('i', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10.5, color: SimColors.muted)),
      ),
    );
  }
}

/// Header for a category in the dashboard
class CategoryHeader extends StatelessWidget {
  final String title;
  const CategoryHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SimColors.brassLight,
        ),
      ),
    );
  }
}

/// Tile for a simulator in the dashboard
class SimulatorTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SimulatorTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SimulatorTile> createState() => _SimulatorTileState();
}

class _SimulatorTileState extends State<SimulatorTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withAlpha(20) : Colors.white.withAlpha(10),
            border: Border.all(
              color: _isHovered ? SimColors.brassLight : Colors.white.withAlpha(35),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SimColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: SimColors.brassLight, size: 24),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: SimColors.heroText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: SimColors.heroSub,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header for individual simulator pages
class SimulatorPageHeader extends StatelessWidget {
  final String title;
  final String description;

  const SimulatorPageHeader({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SimColors.ink, SimColors.ink2],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SIMULATION PÉDAGOGIQUE — NON CONTRACTUELLE',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                letterSpacing: 1.5,
                fontSize: 11,
                color: SimColors.brassLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
                fontSize: 28,
                height: 1.12,
                color: SimColors.heroText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: SimColors.heroSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small inline badge (chip) for statuses or labels.
class SimBadge extends StatelessWidget {
  final String label;
  final Color color;

  const SimBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(34),
        border: Border.all(color: color.withAlpha(85)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontSize: 11.5, 
          fontWeight: FontWeight.w600, 
          color: color, 
          fontFamily: 'IBMPlexMono'
        ),
      ),
    );
  }
}
