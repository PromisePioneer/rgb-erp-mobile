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
  String? _error;
  Timer? _debounceTimer;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _loadSelectedOptions();
  }

  void _loadSelectedOptions() async {
    try {
      final allOptions = await widget.loadOptions('');
      if (mounted) {
        setState(() {
          _allSelectedOptions = allOptions;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void didUpdateWidget(AsyncSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIds != widget.selectedIds) {
      _loadSelectedOptions();
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
    // Call _fetchOptions first: it synchronously flips _isLoading = true
    // (via setState) before hitting its first await, so by the time the
    // overlay is created right after, it captures isLoading = true and
    // shows the spinner immediately instead of a flash of "Tidak ada hasil".
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
    // IMPORTANT: measure the field's own RenderBox HERE, using this widget's
    // context (already laid out in the tree). Do NOT try to measure it from
    // inside the overlay builder below - that context belongs to a brand new
    // subtree living in the Overlay, which hasn't been laid out yet, so
    // findRenderObject() there returns null/no-size and the dropdown
    // silently renders nothing.
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
              fontWeight: FontWeight.w500,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.disabled ? AppColors.slate100 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips + Search
                  if (widget.selectedIds.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...widget.selectedIds.map((id) {
                          final option = _allSelectedOptions.firstWhere(
                                (o) => o.id == id,
                            orElse: () => AsyncSelectOption(id: id, name: '...'),
                          );
                          return Chip(
                            label: Text(option.name, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: widget.disabled ? null : () => _removeSelection(id),
                            backgroundColor: AppColors.primary.withAlpha(26),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            deleteIconColor: AppColors.slate600,
                          );
                        }),
                        // Only show the inline search box for multi-select
                        // fields (so the user can keep adding more items).
                        // Single-select already has its one value picked -
                        // tap the field itself to reopen the dropdown and
                        // change it instead.
                        if (widget.multiSelect)
                          SizedBox(
                            height: 24,
                            width: 120,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              enabled: !widget.disabled,
                              onChanged: _onSearchChanged,
                              onTap: _openDropdown,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Ketik...',
                                hintStyle: TextStyle(fontSize: 12, color: AppColors.slate400),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
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
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown overlay content. Rebuilds automatically whenever MediaQuery
/// (in particular viewInsets.bottom, i.e. the keyboard) changes, because
/// it reads MediaQuery.of(context) directly in build() and Flutter
/// schedules a rebuild for any dependent widget when metrics change.
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

  static const double _dropdownHeight = 200;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    final availableBelow = screenHeight - keyboardHeight - fieldPosition.dy - fieldSize.height;
    final availableAbove = fieldPosition.dy;

    final showAbove = availableBelow < _dropdownHeight && availableAbove > availableBelow;
    final offsetY = showAbove ? -(_dropdownHeight + 4) : fieldSize.height + 4;

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
        // Dropdown positioned above or below the field depending on
        // available space (recomputed every rebuild, so it reacts live
        // to the keyboard opening/closing).
        Positioned(
          width: fieldSize.width,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, offsetY),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: _dropdownHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading && options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null && options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Tidak ada hasil', style: TextStyle(color: AppColors.slate500)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedIds.contains(option.id);

        return InkWell(
          onTap: () => onToggle(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected ? AppColors.primary.withAlpha(26) : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.slate800,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected) Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}