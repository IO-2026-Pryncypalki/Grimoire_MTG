import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/card_search_filters.dart';

class SearchFiltersPanel extends StatefulWidget {
  const SearchFiltersPanel({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final CardSearchFilters filters;
  final ValueChanged<CardSearchFilters> onChanged;

  @override
  State<SearchFiltersPanel> createState() => _SearchFiltersPanelState();
}

class _SearchFiltersPanelState extends State<SearchFiltersPanel> {
  late final TextEditingController _cmcController;

  static const _colorDefs = [
    (code: 'W', label: 'W', bg: Color(0xFFF5EEC8), fg: Color(0xFF5A4800)),
    (code: 'U', label: 'U', bg: Color(0xFF1565C0), fg: Color(0xFFFFFFFF)),
    (code: 'B', label: 'B', bg: Color(0xFF2D2D2D), fg: Color(0xFFFFFFFF)),
    (code: 'R', label: 'R', bg: Color(0xFFC62828), fg: Color(0xFFFFFFFF)),
    (code: 'G', label: 'G', bg: Color(0xFF2E7D32), fg: Color(0xFFFFFFFF)),
    (code: 'C', label: 'C', bg: Color(0xFF9E9E9E), fg: Color(0xFFFFFFFF)),
  ];

  static const _rarities = [
    (code: 'common', label: 'C'),
    (code: 'uncommon', label: 'U'),
    (code: 'rare', label: 'R'),
    (code: 'mythic', label: 'M'),
  ];

  @override
  void initState() {
    super.initState();
    _cmcController = TextEditingController(
      text: widget.filters.cmc?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(SearchFiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.cmc != null && widget.filters.cmc == null) {
      _cmcController.clear();
    }
  }

  @override
  void dispose() {
    _cmcController.dispose();
    super.dispose();
  }

  void _toggleColor(String code) {
    final colors = Set<String>.from(widget.filters.colors);
    if (colors.contains(code)) {
      colors.remove(code);
    } else {
      colors.add(code);
    }
    widget.onChanged(widget.filters.copyWith(
      colors: colors,
      // Reset exact flag when fewer than 2 colors remain — not meaningful then.
      exactColors: colors.length < 2 ? false : null,
    ));
  }

  void _selectRarity(String code) {
    final newRarity = widget.filters.rarity == code ? null : code;
    widget.onChanged(widget.filters.copyWith(rarity: newRarity));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final def in _colorDefs)
            _ColorChip(
              code: def.code,
              bg: def.bg,
              fg: def.fg,
              selected: widget.filters.colors.contains(def.code),
              onTap: () => _toggleColor(def.code),
            ),
          if (widget.filters.colors.length >= 2)
            FilterChip(
              label: Text(l10n.searchFilterExactColors),
              selected: widget.filters.exactColors,
              onSelected: (v) =>
                  widget.onChanged(widget.filters.copyWith(exactColors: v)),
              visualDensity: VisualDensity.compact,
              avatar: widget.filters.exactColors
                  ? const Icon(Icons.check, size: 14)
                  : null,
            ),
          const SizedBox(width: 4),
          _TypeDropdown(
            value: widget.filters.type,
            onChanged: (v) => widget.onChanged(widget.filters.copyWith(type: v)),
          ),
          const SizedBox(width: 4),
          for (final r in _rarities)
            _RarityChip(
              code: r.code,
              label: r.label,
              selected: widget.filters.rarity == r.code,
              onTap: () => _selectRarity(r.code),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _cmcController,
              decoration: InputDecoration(
                labelText: l10n.searchFilterCmc,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v.trim());
                widget.onChanged(widget.filters.copyWith(cmc: n));
              },
            ),
          ),
          if (!widget.filters.isEmpty)
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: Text(l10n.searchFilterClear),
              onPressed: () => widget.onChanged(const CardSearchFilters()),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.code,
    required this.bg,
    required this.fg,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final Color bg;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: code,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? bg : bg.withValues(alpha: 0.3),
            border: Border.all(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              code,
              style: TextStyle(
                color: selected ? fg : fg.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _rarityColors = {
    'common': Color(0xFF616161),
    'uncommon': Color(0xFF546E7A),
    'rare': Color(0xFFAA8800),
    'mythic': Color(0xFFBF360C),
  };

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColors[code] ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? rarityColor : rarityColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? rarityColor : rarityColor.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : rarityColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: value,
        hint: Text(
          l10n.searchFilterType,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(l10n.searchFilterTypeAny),
          ),
          DropdownMenuItem(
            value: 'creature',
            child: Text(l10n.searchFilterTypeCreature),
          ),
          DropdownMenuItem(
            value: 'instant',
            child: Text(l10n.searchFilterTypeInstant),
          ),
          DropdownMenuItem(
            value: 'sorcery',
            child: Text(l10n.searchFilterTypeSorcery),
          ),
          DropdownMenuItem(
            value: 'enchantment',
            child: Text(l10n.searchFilterTypeEnchantment),
          ),
          DropdownMenuItem(
            value: 'artifact',
            child: Text(l10n.searchFilterTypeArtifact),
          ),
          DropdownMenuItem(
            value: 'planeswalker',
            child: Text(l10n.searchFilterTypePlaneswalker),
          ),
          DropdownMenuItem(
            value: 'land',
            child: Text(l10n.searchFilterTypeLand),
          ),
        ],
        onChanged: (v) => onChanged(v),
      ),
    );
  }
}
