import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goal_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();

  List<GoalModel> _goals = [];
  List<GoalModel> get goals => _goals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Aportes de la meta abierta en el detalle (para el gráfico de progreso).
  List<GoalContributionModel> _contributions = [];
  List<GoalContributionModel> get contributions => _contributions;

  bool _isLoadingContributions = false;
  bool get isLoadingContributions => _isLoadingContributions;

  /// Resultado del último aporte (delta real de SmartScore + estado de la meta).
  ContributeResult? _lastContributeResult;
  ContributeResult? get lastContributeResult => _lastContributeResult;

  Future<void> loadGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _goals = await _goalService.getGoals();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  GoalModel? goalById(int id) {
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Crea una meta. Devuelve la meta creada (con id real del backend) para
  /// alimentar la pantalla de éxito 1C-success, o `null` si falló.
  Future<GoalModel?> createGoal({
    required String nombre,
    String? descripcion,
    required double montoObjetivo,
    DateTime? fechaLimite,
    String categoria = 'otros',
    bool recordatorio = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newGoal = GoalModel(
        id: 0,
        userId: 0,
        nombre: nombre,
        descripcion: descripcion,
        montoObjetivo: montoObjetivo,
        saldoAcumulado: 0.0,
        fechaLimite: fechaLimite,
        estado: EstadoMeta.enProgreso,
        categoria: categoria,
        recordatorio: recordatorio,
        createdAt: DateTime.now(),
      );
      final created = await _goalService.createGoal(newGoal);
      await loadGoals();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGoal({
    required int goalId,
    String? nombre,
    double? montoObjetivo,
    DateTime? fechaLimite,
    String? categoria,
    bool? recordatorio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _goalService.updateGoal(
        goalId: goalId,
        nombre: nombre,
        montoObjetivo: montoObjetivo,
        fechaLimite: fechaLimite,
        categoria: categoria,
        recordatorio: recordatorio,
      );
      await loadGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContributions(int goalId) async {
    _isLoadingContributions = true;
    notifyListeners();
    try {
      _contributions = await _goalService.getContributions(goalId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _contributions = [];
    } finally {
      _isLoadingContributions = false;
      notifyListeners();
    }
  }

  Future<bool> contribute({
    required int goalId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _lastContributeResult =
          await _goalService.contributeToGoal(goalId, amount);
      await loadGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGoal(int goalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _goalService.deleteGoal(goalId);
      await loadGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
