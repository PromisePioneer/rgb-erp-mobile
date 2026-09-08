import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../shared/constants/condition_constants.dart';

/// Option item for AsyncSelect
/// id can be int or String depending on the use case
class AsyncSelectOption {
  final dynamic id;
  final String name;
  final String? description;
  final String? condition;
  final String? conditionLabel;
  final double? stock;
  final String? qrCode;

  AsyncSelectOption({
    required this.id,
    required this.name,
    this.description,
    this.condition,
    this.conditionLabel,
    this.stock,
    this.qrCode,
  });

  factory AsyncSelectOption.fromJson(Map<String, dynamic> json) {
    return AsyncSelectOption(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? json['id'] ?? 0,
      name: json['name'] as String,
      description: json['description'] as String?,
      condition: json['current_condition'] as String?,
      conditionLabel: json['current_condition_label'] as String?,
      stock: (json['current_stock'] as num?)?.toDouble(),
      qrCode: json['qr_code'] as String?,
    );
  }
}

/// Async Select Field - Searchable dropdown like Select2
class AsyncSelectField extends StatefulWidget {
  final String? label;
  final String placeholder;
  final Future<List<AsyncSelectOption>> Function(String query) loadOptions;
  final Set<dynamic> selectedIds;
  final ValueChanged<Set<dynamic>> onSelectionChanged;
  final bool multiSelect;
  final bool disabled;
  final int minSearchChars;
  final int debounceMs;
  /// Pre-populated options for initial selected items (e.g., when editing)
  final List<AsyncSelectOption>? initialOptions;

  const AsyncSelectField({
    super.key,
    this.label,
    this.placeholder = 'Ketik untuk mencari...',
    required this.loadOptions,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.multiSelect = true,
    this.disabled = false,
    this.minSearchChars = 0,
    this.debounceMs = 300,
    this.initialOptions,
  });

  @override
  State<AsyncSelectField> createState() => _AsyncSelectFieldState();
}

class _AsyncSelectFieldState extends State<AsyncSelectField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<AsyncSelectOption> _options = [];
  List<AsyncSelectOption> _allSelectedOptions = [];
  bool _isLoading = false;
  bool _initialOptionsLoaded = false;
  String? _error;
  Timer? _debounceTimer;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // If initialOptions are provided (edit mode), use them immediately
    if (widget.initialOptions != null && widget.initialOptions!.isNotEmpty) {
      _allSelectedOptions = List.from(widget.initialOptions!);
      _initialOptionsLoaded = true;
    }

    _loadSelectedOptions();
  }

  @override
  void didUpdateWidget(AsyncSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If initialOptions changed (new data loaded), update _allSelectedOptions
    if (widget.initialOptions != null &&
        widget.initialOptions != oldWidget.initialOptions &&
        widget.initialOptions!.isNotEmpty) {
      // Merge initial options with loaded options
      final existingIds = _allSelectedOptions.map((o) => o.id).toSet();
      for (final opt in widget.initialOptions!) {
        if (!existingIds.contains(opt.id)) {
          _allSelectedOptions.add(opt);
        }
      }
      _initialOptionsLoaded = true;
    }

    // If selectedIds changed, reload options
    if (oldWidget.selectedIds != widget.selectedIds) {
      _loadSelectedOptions();
    }
  }

  void _loadSelectedOptions() async {
    try {
      final allOptions = await widget.loadOptions('');
      if (mounted) {
        setState(() {
          // Merge loaded options with any initial options
          final existingIds = _allSelectedOptions.map((o) => o.id).toSet();
          for (final opt in allOptions) {
            if (!existingIds.contains(opt.id)) {
              _allSelectedOptions.add(opt);
            }
          }
          _initialOptionsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data';
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isOpen) {
      _closeDropdown();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.length < widget.minSearchChars) return;

    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      _fetchOptions(query);
    });
  }

  Future<void> _fetchOptions(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final options = await widget.loadOptions(query);
      if (mounted) {
        setState(() {
          _options = options;
          for (var opt in options) {
            if (widget.selectedIds.contains(opt.id)) {
              if (!_allSelectedOptions.any((o) => o.id == opt.id)) {
                _allSelectedOptions.add(opt);
              }
            }
          }
          _isLoading = false;
        });
        // Refresh overlay content now that data is ready
        _overlayEntry?.markNeedsBuild();
        if (_isOpen) {
          _ensureOverlayCreated();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data';
          _isLoading = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  void _openDropdown() {
    if (widget.disabled) return;
    if (_isOpen) return;

    setState(() {
      _isOpen = true;
    });
    _fetchOptions('');
    _ensureOverlayCreated();
  }

  void _closeDropdown() {
    setState(() {
      _isOpen = false;
    });
    _ensureOverlayRemoved();
    _searchController.clear();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _ensureOverlayCreated() {
    if (_overlayEntry == null && _isOpen && mounted) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _ensureOverlayRemoved() {
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size fieldSize = renderBox.size;
    final Offset fieldPosition = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => _DropdownOverlay(
        layerLink: _layerLink,
        onClose: _closeDropdown,
        options: _options,
        isLoading: _isLoading,
        error: _error,
        selectedIds: widget.selectedIds,
        onToggle: _toggleSelection,
        onRetry: () => _fetchOptions(_searchController.text),
        fieldPosition: fieldPosition,
        fieldSize: fieldSize,
        getSelectedIds: () => widget.selectedIds,
      ),
    );
  }

  void _toggleSelection(AsyncSelectOption option) {
    final newSelection = Set<dynamic>.from(widget.selectedIds);

    if (newSelection.contains(option.id)) {
      newSelection.remove(option.id);
    } else {
      if (widget.multiSelect) {
        newSelection.add(option.id);
        if (!_allSelectedOptions.any((o) => o.id == option.id)) {
          _allSelectedOptions.add(option);
        }
      } else {
        newSelection.clear();
        newSelection.add(option.id);
        _allSelectedOptions = [option];
        widget.onSelectionChanged(newSelection);
        _closeDropdown();
        return;
      }
    }

    widget.onSelectionChanged(newSelection);
    _overlayEntry?.markNeedsBuild();
  }

  void _removeSelection(int id) {
    final newSelection = Set<dynamic>.from(widget.selectedIds);
    newSelection.remove(id);
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              decoration: BoxDecoration(
                color: widget.disabled ? theme.colors.muted : theme.colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isOpen ? theme.colors.primary : theme.colors.border,
                  width: _isOpen ? 1.5 : 1,
                ),
              ),
              child: widget.selectedIds.isNotEmpty
                  ? _buildSelectedChips(theme)
                  : _buildSearchField(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChips(FThemeData theme) {
    // For single-select, show as a text with clear button
    if (!widget.multiSelect && widget.selectedIds.length == 1) {
      final selectedId = widget.selectedIds.first;
      final option = _allSelectedOptions.firstWhere(
        (o) => o.id == selectedId,
        orElse: () => AsyncSelectOption(id: selectedId, name: '...'),
      );

      final isLoading = !_initialOptionsLoaded && option.name == '...';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: isLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Memuat...',
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      option.name,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: option.name == '...' ? theme.colors.mutedForeground : theme.colors.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (!widget.disabled && !isLoading)
              GestureDetector(
                onTap: () => _removeSelection(selectedId),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // For multi-select, show chips with inline search
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips - compact
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...widget.selectedIds.map((id) {
                final option = _allSelectedOptions.firstWhere(
                  (o) => o.id == id,
                  orElse: () => AsyncSelectOption(id: id, name: '...'),
                );
                return _SelectChip(
                  label: option.name,
                  onDelete: widget.disabled ? null : () => _removeSelection(id),
                );
              }),
              // Inline search for multi-select - smaller
              if (widget.multiSelect)
                SizedBox(
                  height: 24,
                  width: 80,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    enabled: !widget.disabled,
                    onChanged: _onSearchChanged,
                    onTap: _openDropdown,
                    style: theme.typography.body.sm,
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      filled: true,
                      fillColor: theme.colors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: theme.colors.mutedForeground,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              enabled: !widget.disabled,
              onChanged: _onSearchChanged,
              onTap: _openDropdown,
              style: theme.typography.body.sm,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: theme.typography.body.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: theme.colors.mutedForeground,
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// Stylized chip for selected items - compact
class _SelectChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;

  const _SelectChip({
    required this.label,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colors.primary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 10,
                  color: theme.colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown overlay content
class _DropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final VoidCallback onClose;
  final List<AsyncSelectOption> options;
  final bool isLoading;
  final String? error;
  final Set<dynamic> selectedIds;
  final ValueChanged<AsyncSelectOption> onToggle;
  final VoidCallback onRetry;
  final Offset fieldPosition;
  final Size fieldSize;
  /// Callback to get current selectedIds, so overlay always has fresh selection state
  final Set<dynamic> Function() getSelectedIds;

  const _DropdownOverlay({
    required this.layerLink,
    required this.onClose,
    required this.options,
    required this.isLoading,
    required this.error,
    required this.selectedIds,
    required this.onToggle,
    required this.onRetry,
    required this.fieldPosition,
    required this.fieldSize,
    required this.getSelectedIds,
  });

  // Compact sizes
  static const double _dropdownHeight = 160;
  static const double _dropdownMaxHeightWithKeyboard = 120;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final isKeyboardOpen = keyboardHeight > 0;

    // Calculate available space
    final availableBelow = screenHeight - keyboardHeight - fieldPosition.dy - fieldSize.height;
    final availableAbove = fieldPosition.dy - keyboardHeight;

    // When keyboard is open, show dropdown above keyboard
    // Otherwise, show based on available space
    final showAbove = isKeyboardOpen
        ? true  // Always show above when keyboard is open
        : (availableBelow < _dropdownHeight && availableAbove > availableBelow);

    // Adjust height based on keyboard state
    final maxHeight = isKeyboardOpen
        ? (availableAbove > _dropdownMaxHeightWithKeyboard
            ? _dropdownMaxHeightWithKeyboard
            : availableAbove - 20)  // Leave some padding
        : _dropdownHeight;

    // Calculate offset
    final double offsetY;
    if (isKeyboardOpen) {
      // Position dropdown above keyboard
      offsetY = fieldPosition.dy - maxHeight - keyboardHeight - 8;
    } else {
      offsetY = showAbove ? -(_dropdownHeight + 4) : fieldSize.height + 4;
    }

    return Stack(
      children: [
        // Tap barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Dropdown positioned above or below the field
        Positioned(
          width: fieldSize.width,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, offsetY),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight.clamp(100.0, _dropdownHeight),
              ),
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildContent(theme, isKeyboardOpen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(FThemeData theme, bool isKeyboardOpen) {
    if (isLoading && options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Memuat...',
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null && options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colors.error,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              error!,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FButton(
              onPress: onRetry,
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: theme.colors.mutedForeground,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada hasil',
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        shrinkWrap: true,
        // Use BouncingScrollPhysics for iOS-like feel, or clamp when keyboard is open
        physics: isKeyboardOpen
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: options.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.colors.border,
        ),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = getSelectedIds().contains(option.id);

          return GestureDetector(
            onTap: () => onToggle(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: isSelected ? theme.colors.primary.withAlpha(15) : null,
              child: Row(
                children: [
                  // Checkbox indicator - smaller
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? theme.colors.primary : theme.colors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: theme.colors.primaryForeground,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.name,
                          style: theme.typography.body.sm.copyWith(
                            color: isSelected ? theme.colors.primary : theme.colors.foreground,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (option.qrCode != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            'QR: ${option.qrCode}',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (option.conditionLabel != null || option.stock != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (option.conditionLabel != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _getConditionColor(option.condition, theme),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    option.conditionLabel!,
                                    style: theme.typography.body.xs.copyWith(
                                      color: theme.colors.foreground,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                              if (option.conditionLabel != null && option.stock != null)
                                const SizedBox(width: 6),
                              if (option.stock != null) ...[
                                Icon(
                                  Icons.inventory_2,
                                  size: 10,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${option.stock!.toStringAsFixed(0)}',
                                  style: theme.typography.body.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (option.description != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            option.description!,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getConditionColor(String? condition, FThemeData theme) {
    if (condition == null) return theme.colors.muted;

    // Use centralized condition colors
    if (NonChemicalConditions.isValid(condition)) {
      final rank = NonChemicalConditions.getRank(condition);
      if (rank >= 4) return Colors.green.shade100;
      if (rank >= 3) return Colors.green.shade200;
      if (rank >= 2) return Colors.yellow.shade100;
      return Colors.red.shade100;
    }

    if (ChemicalConditions.isValid(condition)) {
      final rank = ChemicalConditions.getRank(condition);
      if (rank >= 3) return Colors.green.shade100;
      if (rank >= 2) return Colors.yellow.shade100;
      return Colors.red.shade100;
    }

    return theme.colors.muted;
  }
}
