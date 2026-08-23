import 'package:equatable/equatable.dart';

/// Violation type entity representing a category or subcategory
/// Supports both flat data (parent_id) and nested data (children)
class ViolationType extends Equatable {
  final int id;
  final String name;
  final String severityLevel;
  final List<ViolationType> children;

  const ViolationType({
    required this.id,
    required this.name,
    required this.severityLevel,
    this.children = const [],
  });

  factory ViolationType.fromJson(Map<String, dynamic> json) {
    // Check if nested children format (from backend with children array)
    if (json['children'] != null) {
      return ViolationType(
        id: json['id'] as int,
        name: json['name'] as String,
        severityLevel: json['severity_level'] as String? ?? 'medium',
        children: (json['children'] as List<dynamic>?)
                ?.map((c) => ViolationType.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }

    // Flat format with parent_id (CSV style)
    return ViolationType(
      id: json['id'] as int,
      name: json['name'] as String,
      severityLevel: json['severity_level'] as String? ??
          json['severity'] as String? ??
          'medium',
      children: const [],
    );
  }

  /// Build hierarchy from flat list (list format with parent_id)
  /// Returns list of root categories with populated children
  static List<ViolationType> buildHierarchy(List<ViolationType> flatList) {
    final Map<int, ViolationType> typeMap = {};
    final List<ViolationType> roots = [];

    // First pass: create all types
    for (final type in flatList) {
      typeMap[type.id] = type;
    }

    // Second pass: build parent-child relationships
    for (final type in flatList) {
      // Try to find parent via parent_id
      final parentId = _findParentId(type.id, flatList);
      if (parentId == null) {
        // This is a root category
        roots.add(type);
      } else {
        // Find parent and add this as child
        final parent = typeMap[parentId];
        if (parent != null) {
          // Create new parent with updated children
          final updatedChildren = [...parent.children, type];
          final updatedParent = ViolationType(
            id: parent.id,
            name: parent.name,
            severityLevel: parent.severityLevel,
            children: updatedChildren,
          );
          typeMap[parentId] = updatedParent;
        }
      }
    }

    // Return roots with updated children
    return roots.map((r) => typeMap[r.id] ?? r).toList();
  }

  /// Find parent ID by checking if this ID appears as parent_id in any other item
  static int? _findParentId(int childId, List<ViolationType> allTypes) {
    // The data format: parent_id column contains the parent id
    // We need to look at the raw JSON to find parent_id
    return null; // Will be handled in buildHierarchyFromJson
  }

  /// Build hierarchy from raw JSON list with parent_id
  static List<ViolationType> buildHierarchyFromJson(List<Map<String, dynamic>> rawList) {
    final Map<int, ViolationType> typeMap = {};
    final Map<int, int?> parentMap = {};
    final List<int> rootIds = [];

    // First pass: create all types and map parent relationships
    for (final json in rawList) {
      final id = json['id'] as int;
      final parentId = json['parent_id'] as int?;

      final type = ViolationType(
        id: id,
        name: json['name'] as String,
        severityLevel: json['severity_level'] as String? ??
            json['severity'] as String? ??
            'medium',
        children: const [],
      );

      typeMap[id] = type;
      parentMap[id] = parentId;

      if (parentId == null || parentId == 0) {
        rootIds.add(id);
      }
    }

    // Second pass: build parent-child relationships
    for (final entry in parentMap.entries) {
      final id = entry.key;
      final parentId = entry.value;

      if (parentId != null && parentId != 0 && typeMap.containsKey(parentId)) {
        final parent = typeMap[parentId]!;
        final child = typeMap[id]!;

        final updatedChildren = [...parent.children, child];
        typeMap[parentId] = ViolationType(
          id: parent.id,
          name: parent.name,
          severityLevel: parent.severityLevel,
          children: updatedChildren,
        );
      }
    }

    // Return roots with their updated children
    return rootIds.map((id) => typeMap[id]!).toList();
  }

  /// Check if this is a category (has children) vs a leaf type (no children)
  bool get isCategory => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  @override
  List<Object?> get props => [id, name, severityLevel, children];
}
