import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/daily_task.dart';

DailyTaskRepository createDailyTaskRepository(Dio dio) {
  return DailyTaskRepository(api: DailyTaskApi(dio));
}

class DailyTaskRepository {
  final DailyTaskApi api;

  DailyTaskRepository({required this.api});

  Future<List<DailyTask>> getTodayTasks() async {
    try {
      final response = await api.getTodayTasks();
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTask.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat tugas harian: $e',
        statusCode: 500,
      );
    }
  }

  Future<DailyTask> getTaskDetail(int taskId) async {
    try {
      final response = await api.getTaskDetail(taskId);
      final data = response['data'];
      if (data == null) {
        throw ApiException(message: 'Tugas tidak ditemukan', statusCode: 404);
      }
      return DailyTask.fromJson(_toMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat detail tugas: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskMasterItem>> getItems({String? query, List<int>? positionIds}) async {
    try {
      final response = await api.getItems(query: query, positionIds: positionIds);
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskMasterItem.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar item: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskPosition>> getPositions() async {
    try {
      final response = await api.getPositions();
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskPosition.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar posisi: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskTool>> getTools({String? query}) async {
    try {
      final response = await api.getTools(query: query);
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskTool.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar tools: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskChemical>> getChemicals({String? query}) async {
    try {
      final response = await api.getChemicals(query: query);
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskChemical.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar chemicals: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskPpe>> getPpes({String? query}) async {
    try {
      final response = await api.getPpes(query: query);
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskPpe.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar PPE: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<DailyTaskMachine>> getMachines({String? query}) async {
    try {
      final response = await api.getMachines(query: query);
      final data = response['data'];
      if (data == null) return [];
      final list = data is List ? data : [];
      return list.map((json) => DailyTaskMachine.fromJson(_toMap(json))).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar mesin: $e',
        statusCode: 500,
      );
    }
  }

  Future<Map<String, dynamic>> getHistory({int page = 1, int perPage = 15}) async {
    try {
      return await api.getHistory(page: page, perPage: perPage);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat riwayat tugas: $e',
        statusCode: 500,
      );
    }
  }

  Future<DailyTask> startTask({
    required int taskId,
    required List<String> photos,
    List<Map<String, String>>? toolConditions,
    List<Map<String, String>>? ppeConditions,
    List<Map<String, String>>? machineConditions,
    List<Map<String, String>>? chemicalConditions,
  }) async {
    try {
      final response = await api.startTask(
        taskId: taskId,
        photos: photos,
        toolConditions: toolConditions,
        ppeConditions: ppeConditions,
        machineConditions: machineConditions,
        chemicalConditions: chemicalConditions,
      );
      final data = response['data'];
      if (data == null) {
        throw ApiException(message: 'Format response tidak valid', statusCode: 500);
      }
      return DailyTask.fromJson(_toMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memulai tugas: $e',
        statusCode: 500,
      );
    }
  }

  Future<DailyTask> finishTask({
    required int taskId,
    required List<String> photos,
    String? notes,
    List<Map<String, String>>? toolConditions,
    List<Map<String, String>>? ppeConditions,
    List<Map<String, String>>? machineConditions,
    List<Map<String, String>>? chemicalConditions,
  }) async {
    try {
      final response = await api.finishTask(
        taskId: taskId,
        photos: photos,
        notes: notes,
        toolConditions: toolConditions,
        ppeConditions: ppeConditions,
        machineConditions: machineConditions,
        chemicalConditions: chemicalConditions,
      );
      final data = response['data'];
      if (data == null) {
        throw ApiException(message: 'Format response tidak valid', statusCode: 500);
      }
      return DailyTask.fromJson(_toMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menyelesaikan tugas: $e',
        statusCode: 500,
      );
    }
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  // ====================
  // Supervisor Assignment Methods
  // ====================

  Future<List<Map<String, dynamic>>> getAssignments({int page = 1, int perPage = 15, String? status}) async {
    try {
      final response = await api.getAssignments(page: page, perPage: perPage, status: status);
      final data = response['data'];
      if (data == null) return [];
      return (data is List ? data : []).map((json) => _toMap(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar tugas: $e',
        statusCode: 500,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentEmployees() async {
    try {
      final response = await api.getAssignmentEmployees();
      final data = response['data'];
      if (data == null) return [];
      return (data is List ? data : []).map((json) => _toMap(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar karyawan: $e',
        statusCode: 500,
      );
    }
  }

  Future<bool> createAssignment({
    required int employeeId,
    int? targetMinutes,
    String? assignedDate,
    String? notes,
  }) async {
    try {
      await api.createAssignment(
        employeeId: employeeId,
        targetMinutes: targetMinutes,
        assignedDate: assignedDate,
        notes: notes,
      );
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat tugas: $e',
        statusCode: 500,
      );
    }
  }

  Future<bool> deleteAssignment(int id) async {
    try {
      await api.deleteAssignment(id);
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus tugas: $e',
        statusCode: 500,
      );
    }
  }

  /// DELETE /daily-task/{id} - Delete/cancel a task (for TL)
  Future<bool> deleteTask(int taskId) async {
    try {
      await api.deleteTask(taskId);
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menghapus tugas: $e',
        statusCode: 500,
      );
    }
  }

  /// PUT /daily-task/{id} - Update a task (for TL)
  Future<Map<String, dynamic>?> updateTask({
    required int taskId,
    List<int>? employeeIds,
    int? itemId,
    String? assignedDate,
    int? targetMinutes,
    String? notes,
    List<int>? toolIds,
    List<int>? chemicalIds,
    List<int>? ppeIds,
  }) async {
    try {
      final response = await api.updateTask(
        taskId: taskId,
        employeeIds: employeeIds,
        itemId: itemId,
        assignedDate: assignedDate,
        targetMinutes: targetMinutes,
        notes: notes,
        toolIds: toolIds,
        chemicalIds: chemicalIds,
        ppeIds: ppeIds,
      );
      return response['data'] as Map<String, dynamic>?;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memperbarui tugas: $e',
        statusCode: 500,
      );
    }
  }

  // ====================
  // Mobile Task Assignment (uses daily_task_assign privilege)
  // ====================

  /// GET /daily-task/assign/employees - Get employees for mobile assignment
  Future<List<Map<String, dynamic>>> getMobileAssignEmployees({String? query}) async {
    try {
      final response = await api.getMobileAssignEmployees(query: query);
      final data = response['data'];
      if (data == null) return [];
      return (data is List ? data : []).map((json) => _toMap(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat daftar karyawan: $e',
        statusCode: 500,
      );
    }
  }

  /// POST /daily-task/assign - Assign task using mobile API (supports multiple employees)
  /// Returns the created assignment data
  Future<Map<String, dynamic>?> mobileAssignTask({
    required List<int> employeeIds,
    int? itemId,
    int? areaId,
    int? targetMinutes,
    String? targetNote,
    String? notes,
    String? assignedDate,
    List<int>? toolIds,
    List<int>? chemicalIds,
    List<int>? ppeIds,
    List<int>? machineIds,
  }) async {
    try {
      final response = await api.mobileAssignTask(
        employeeIds: employeeIds,
        itemId: itemId,
        areaId: areaId,
        targetMinutes: targetMinutes,
        targetNote: targetNote,
        notes: notes,
        assignedDate: assignedDate,
        toolIds: toolIds,
        chemicalIds: chemicalIds,
        ppeIds: ppeIds,
        machineIds: machineIds,
      );
      // Return the created assignment data from response
      return response['data'] as Map<String, dynamic>?;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal membuat tugas: $e',
        statusCode: 500,
      );
    }
  }

  /// GET /daily-task/my-assignments - Get tasks assigned by current user (TL)
  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final response = await api.getMyAssignments();
      final data = response['data'];
      if (data == null) return [];
      return (data is List ? data : []).map((json) => _toMap(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat tugas: $e',
        statusCode: 500,
      );
    }
  }

  /// GET /daily-task/review-criteria - Get review criteria
  Future<List<Map<String, dynamic>>> getReviewCriteria() async {
    try {
      final response = await api.getReviewCriteria();
      final data = response['data'];
      if (data == null) return [];
      return (data is List ? data : []).map((json) => _toMap(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal memuat kriteria review: $e',
        statusCode: 500,
      );
    }
  }

  /// POST /daily-task/{id}/review - Submit review
  Future<Map<String, dynamic>> submitReview({
    required int taskId,
    required List<Map<String, dynamic>> scores,
    String? notes,
  }) async {
    try {
      final response = await api.submitReview(
        taskId: taskId,
        scores: scores,
        notes: notes,
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Gagal menyimpan review: $e',
        statusCode: 500,
      );
    }
  }
}
