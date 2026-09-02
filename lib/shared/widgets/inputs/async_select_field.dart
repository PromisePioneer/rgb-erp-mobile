import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Option item for AsyncSelect
class AsyncSelectOption {
  final int id;
  final String name;
  final String? description;

  AsyncSelectOption({
    required this.id,
    required this.name,
    this.description,
  });

  factory AsyncSelectOption.fromJson(Map<String, dynamic> json) {
    return AsyncSelectOption(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

/// Async Select Field - Searchable dropdown like Select2
class AsyncSelectField extends StatefulWidget {
  final String? label;
  final String placeholder;
  final Future<List<AsyncSelectOption>> Function(String query) loadOptions;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onSelectionChanged;
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
      ),
    );
  }

  void _toggleSelection(AsyncSelectOption option) {
    final newSelection = Set<int>.from(widget.selectedIds);

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
    final newSelection = Set<int>.from(widget.selectedIds);
    newSelection.remove(id);
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: widget.disabled ? AppColors.slate50 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isOpen ? AppColors.primary : AppColors.slate300,
                  width: _isOpen ? 1.5 : 1,
                ),
              ),
              child: widget.selectedIds.isNotEmpty
                  ? _buildSelectedChips()
                  : _buildSearchField(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChips() {
    // For single-select, show as a text with clear button
    if (!widget.multiSelect && widget.selectedIds.length == 1) {
      final selectedId = widget.selectedIds.first;
      final option = _allSelectedOptions.firstWhere(
        (o) => o.id == selectedId,
        orElse: () => AsyncSelectOption(id: selectedId, name: '...'),
      );

      final isLoading = !_initialOptionsLoaded && option.name == '...';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.slate400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memuat...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: option.name == '...' ? AppColors.slate400 : AppColors.slate800,
                        fontWeight: FontWeight.w500,
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
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.slate600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // For multi-select, show chips with inline search
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
              // Inline search for multi-select
              if (widget.multiSelect)
                SizedBox(
                  height: 28,
                  width: 100,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    enabled: !widget.disabled,
                    onChanged: _onSearchChanged,
                    onTap: _openDropdown,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      filled: true,
                      fillColor: AppColors.slate100,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.slate400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              enabled: !widget.disabled,
              onChanged: _onSearchChanged,
              onTap: _openDropdown,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.slate400,
              size: 22,
            ),
        ],
      ),
    );
  }
}

/// Stylized chip for selected items
class _SelectChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;

  const _SelectChip({
    required this.label,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: AppColors.primary,
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
  final Set<int> selectedIds;
  final ValueChanged<AsyncSelectOption> onToggle;
  final VoidCallback onRetry;
  final Offset fieldPosition;
  final Size fieldSize;

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
  });

  static const double _dropdownHeight = 280;
  static const double _dropdownMaxHeightWithKeyboard = 200;

  @override
  Widget build(BuildContext context) {
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
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight.clamp(100.0, _dropdownHeight),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: _buildContent(isKeyboardOpen),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isKeyboardOpen) {
    if (isLoading && options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Memuat data...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null && options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.slate400,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada hasil',
              style: TextStyle(
                color: AppColors.slate500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ListView.separated(
        shrinkWrap: true,
        // Use BouncingScrollPhysics for iOS-like feel, or clamp when keyboard is open
        physics: isKeyboardOpen
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: options.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.slate100,
        ),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedIds.contains(option.id);

          return InkWell(
            onTap: () => onToggle(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isSelected ? AppColors.primary.withAlpha(15) : null,
              child: Row(
                children: [
                  // Checkbox indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.slate300,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.slate800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (option.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
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
}
