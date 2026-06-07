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

  Future<bool> createGoal({
    required String nombre,
    String? descripcion,
    required double montoObjetivo,
    DateTime? fechaLimite,
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
        createdAt: DateTime.now(),
      );
      await _goalService.createGoal(newGoal);
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

  Future<bool> contribute({
    required int goalId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
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

  Future<void> deleteGoal(int goalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _goalService.deleteGoal(goalId);
      await loadGoals();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
