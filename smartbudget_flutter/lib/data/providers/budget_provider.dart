import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/smartscore_model.dart';
import '../models/alert_model.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../services/smartscore_service.dart';
import '../services/alert_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  final ExpenseService _expenseService = ExpenseService();
  final SmartScoreService _smartScoreService = SmartScoreService();
  final AlertService _alertService = AlertService();

  bool _isLoading = false;
  bool _hasBudget = false;
  bool _showBalance = true;
  String? _errorMessage;

  BudgetModel? _currentBudget;
  List<ExpenseModel> _recentExpenses = [];
  int _currentScore = 0;
  int _scoreVariation = 0;
  List<AlertModel> _activeAlerts = [];

  bool get isLoading => _isLoading;
  bool get hasBudget => _hasBudget;
  bool get showBalance => _showBalance;
  String? get errorMessage => _errorMessage;

  BudgetModel? get currentBudget => _currentBudget;
  List<ExpenseModel> get recentExpenses => _recentExpenses;
  int get currentScore => _currentScore;
  int get scoreVariation => _scoreVariation;
  List<AlertModel> get activeAlerts => _activeAlerts;

  void toggleShowBalance() {
    _showBalance = !_showBalance;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate alerts (non-blocking)
      try {
        await _alertService.generateAlerts();
      } catch (_) {}

      // 2. Fetch current budget
      try {
        _currentBudget = await _budgetService.getCurrentBudget();
        _hasBudget = true;
      } catch (e) {
        if (e.toString().contains('404')) {
          _hasBudget = false;
          _currentBudget = null;
        } else {
          rethrow;
        }
      }

      // 3. If budget exists, load other dashboard details in parallel
      if (_hasBudget) {
        final results = await Future.wait([
          _expenseService.getExpenses(),
          _smartScoreService.getCurrentScore(),
          _smartScoreService.getScoreHistory(meses: 6),
          _alertService.getAlerts(),
        ]);

        _recentExpenses = (results[0] as List<ExpenseModel>).take(5).toList();
        _currentScore = results[1] as int;

        final history = results[2] as List<SmartScoreSnapshotModel>;
        if (history.length >= 2) {
          final currentScore = history.last.score;
          final previousScore = history[history.length - 2].score;
          _scoreVariation = currentScore - previousScore;
        } else {
          _scoreVariation = 0;
        }

        _activeAlerts = results[3] as List<AlertModel>;
      } else {
        _recentExpenses = [];
        _currentScore = 0;
        _scoreVariation = 0;
        _activeAlerts = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> initializeBudget(double montoBase) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      _currentBudget = await _budgetService.createBudget(montoBase, now.month, now.year);
      _hasBudget = true;
      await loadDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerIncome(double monto, String descripcion) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBudget = await _budgetService.addIncome(monto, descripcion);
      await loadDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAlertAsRead(int alertId) async {
    try {
      await _alertService.markAsRead(alertId);
      _activeAlerts = _activeAlerts.map((a) {
        if (a.id == alertId) {
          // Re-create the object with leida = true
          return AlertModel(
            id: a.id,
            userId: a.userId,
            titulo: a.titulo,
            mensaje: a.mensaje,
            tipo: a.tipo,
            leida: true,
            createdAt: a.createdAt,
          );
        }
        return a;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }
}

