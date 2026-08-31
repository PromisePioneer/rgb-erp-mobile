import 'package:flutter/foundation.dart';
import '../../data/repositories/daily_task_repository.dart';
import '../../domain/models/daily_task.dart';

class DailyTaskNotifier extends ChangeNotifier {
  final DailyTaskRepository _repository;

  // Employee task state
  List<DailyTask> _todayTasks = [];
  List<DailyTask> _historyTasks = [];
  DailyTask? _selectedTask;
  List<DailyTaskMasterItem> _items = [];
  List<DailyTaskTool> _tools = [];
  List<DailyTaskChemical> _chemicals = [];
  List<DailyTaskPpe> _ppes = [];

  // Supervisor assignment state
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _assignmentEmployees = [];
  List<Map<String, dynamic>> _mobileAssignEmployees = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // Separate state for master data (tools, chemicals, ppes)
  // to avoid race conditions with task detail loading
  bool _isLoadingMasterData = false;
  String? _masterDataError;
  bool _masterDataLoaded = false;

  DailyTaskNotifier(this._repository);

  // Getters - Employee tasks
  List<DailyTask> get todayTasks => _todayTasks;
  List<DailyTask> get historyTasks => _historyTasks;
  DailyTask? get selectedTask => _selectedTask;
  List<DailyTaskMasterItem> get items => _items;
  List<DailyTaskTool> get tools => _tools;
  List<DailyTaskChemical> get chemicals => _chemicals;
  List<DailyTaskPpe> get ppes => _ppes;

  // Getters - Assignments
  List<Map<String, dynamic>> get assignments => _assignments;
  List<Map<String, dynamic>> get assignmentEmployees => _assignmentEmployees;
  List<Map<String, dynamic>> get mobileAssignEmployees => _mobileAssignEmployees;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // Getters - Master data state (separate to avoid race conditions)
  bool get isLoadingMasterData => _isLoadingMasterData;
  String? get masterDataError => _masterDataError;

  // ====================
  // Employee Methods
  // ====================

  Future<void> loadTodayTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayTasks = await _repository.getTodayTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTaskDetail(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTask = await _repository.getTaskDetail(taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHistory({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getHistory(page: page);
      final data = result['data'] as List<dynamic>?;
      if (data != null) {
        _historyTasks = data.map((json) => DailyTask.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMasterData() async {
    _isLoadingMasterData = true;
    _masterDataError = null;
    _masterDataLoaded = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTools(),
        _repository.getChemicals(),
        _repository.getPpes(),
      ]);

      _tools = results[0] as List<DailyTaskTool>;
      _chemicals = results[1] as List<DailyTaskChemical>;
      _ppes = results[2] as List<DailyTaskPpe>;
      _isLoadingMasterData = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMasterData = false;
      _masterDataError = e.toString();
      notifyListeners();
    }
  }

  /// Load master items (task types) for assignment form
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.getItems();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Retry loading master data only (tools, chemicals, ppes)
  /// Does not affect task detail loading state
  Future<void> retryLoadMasterData() async {
    await loadMasterData();
  }

  Future<bool> startTask({
    required int taskId,
    required List<String> photos,
    List<int>? toolIds,
    List<int>? chemicalIds,
    List<int>? ppeIds,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _repository.startTask(
        taskId: taskId,
        photos: photos,
        toolIds: toolIds,
        chemicalIds: chemicalIds,
        ppeIds: ppeIds,
      );

      _todayTasks = _todayTasks.map((t) => t.id == taskId ? task : t).toList();
      _selectedTask = task;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishTask({
    required int taskId,
    required List<String> photos,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _repository.finishTask(
        taskId: taskId,
        photos: photos,
        notes: notes,
      );

      _todayTasks = _todayTasks.map((t) => t.id == taskId ? task : t).toList();
      _selectedTask = task;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ====================
  // Supervisor Assignment Methods
  // ====================

  Future<void> loadAssignments({int page = 1, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignments = await _repository.getAssignments(page: page, status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAssignmentEmployees() async {
    try {
      _assignmentEmployees = await _repository.getAssignmentEmployees();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createAssignment({
    required int employeeId,
    int? targetMinutes,
    String? assignedDate,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createAssignment(
        employeeId: employeeId,
        targetMinutes: targetMinutes,
        assignedDate: assignedDate,
        notes: notes,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAssignment(int id) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteAssignment(id);
      _assignments = _assignments.where((a) => a['id'] != id).toList();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ====================
  // Common Methods
  // ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMasterDataError() {
    _masterDataError = null;
    notifyListeners();
  }

  void clearSelectedTask() {
    _selectedTask = null;
    notifyListeners();
  }

  /// Check if master data (tools, chemicals, ppes) has been loaded
  /// Returns true if data exists, false if empty or never loaded
  bool get hasMasterData => _tools.isNotEmpty || _chemicals.isNotEmpty || _ppes.isNotEmpty;

  /// Check if master data is currently loading or has an error
  bool get hasMasterDataError => _masterDataError != null;

  /// Check if master data has ever been attempted to load
  /// (can be used to distinguish between "not loaded yet" vs "loaded but empty")
  bool get masterDataWasLoaded => _masterDataLoaded;

  // ====================
  // Mobile Task Assignment Methods (uses daily_task_assign privilege)
  // ====================

  Future<void> loadMobileAssignEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mobileAssignEmployees = await _repository.getMobileAssignEmployees();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> mobileAssignTask({
    required int employeeId,
    int? itemId,
    int? areaId,
    int? targetMinutes,
    String? targetNote,
    String? notes,
    String? assignedDate,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.mobileAssignTask(
        employeeId: employeeId,
        itemId: itemId,
        areaId: areaId,
        targetMinutes: targetMinutes,
        targetNote: targetNote,
        notes: notes,
        assignedDate: assignedDate,
      );
      // Add the new assignment to the list if returned
      if (result != null) {
        _assignments.insert(0, result);
        notifyListeners();
      }
      _isSubmitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignments = await _repository.getMyAssignments();
      _isLoading = false;
      notifyListeners();
      return _assignments;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewCriteria() async {
    try {
      return await _repository.getReviewCriteria();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> submitReview({
    required int taskId,
    required List<Map<String, dynamic>> scores,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.submitReview(
        taskId: taskId,
        scores: scores,
        notes: notes,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
