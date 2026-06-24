import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../models/expense_model.dart';
import '../models/smartscore_model.dart';
import '../services/analysis_service.dart';
import '../services/expense_service.dart';
import '../services/smartscore_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();
  final SmartScoreService _smartScoreService = SmartScoreService();
  final ExpenseService _expenseService = ExpenseService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, double>? _expensesByCategory;
  Map<String, double>? get expensesByCategory => _expensesByCategory;

  List<SmartScoreSnapshotModel> _scoreHistory = [];
  List<SmartScoreSnapshotModel> get scoreHistory => _scoreHistory;

  int _currentScore = 0;
  int get currentScore => _currentScore;

  int _scoreVariation = 0;
  int get scoreVariation => _scoreVariation;

  // ─── Rediseño Análisis: Resumen (1A) ───────────────────────────────────────
  AnalysisOverview? _overview;
  AnalysisOverview? get overview => _overview;

  bool _isOverviewLoading = false;
  bool get isOverviewLoading => _isOverviewLoading;

  // ─── Rediseño Análisis: Detalle de categoría (1D) ──────────────────────────
  CategoryDetail? _categoryDetail;
  CategoryDetail? get categoryDetail => _categoryDetail;

  List<ExpenseModel> _categoryTransactions = [];
  List<ExpenseModel> get categoryTransactions => _categoryTransactions;

  bool _isCategoryLoading = false;
  bool get isCategoryLoading => _isCategoryLoading;

  String? _categoryError;
  String? get categoryError => _categoryError;

  SimulationResult? _simulationResult;
  SimulationResult? get simulationResult => _simulationResult;

  SavingsProjectionResult? _savingsProjection;
  SavingsProjectionResult? get savingsProjection => _savingsProjection;

  bool _isProjecting = false;
  bool get isProjecting => _isProjecting;

  String? _projectionError;
  String? get projectionError => _projectionError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadAnalysisData({int? mes, int? anio}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _analysisService.getExpensesByCategory(mes: mes, anio: anio),
        _smartScoreService.getScoreHistory(meses: 6),
      ]);

      _expensesByCategory = futures[0] as Map<String, double>;
      _scoreHistory = futures[1] as List<SmartScoreSnapshotModel>;

      // SmartScore actual + variación vs. el mes anterior (card de 1A).
      // El score actual no bloquea la pantalla si falla (p. ej. sin presupuesto).
      try {
        _currentScore = await _smartScoreService.getCurrentScore();
      } catch (_) {
        _currentScore = _scoreHistory.isNotEmpty ? _scoreHistory.last.score : 0;
      }
      _scoreVariation = _scoreHistory.length >= 2
          ? _scoreHistory.last.score - _scoreHistory[_scoreHistory.length - 2].score
          : 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las métricas del Resumen (1A) con comparativa al mes anterior.
  Future<void> loadOverview({int? mes, int? anio}) async {
    _isOverviewLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _overview = await _analysisService.getOverview(mes: mes, anio: anio);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isOverviewLoading = false;
      notifyListeners();
    }
  }

  /// Carga el detalle de una categoría (1D): resumen + desglose por comercio
  /// y las transacciones de esa categoría en el mes.
  Future<void> loadCategoryDetail({
    required String categoria,
    int? mes,
    int? anio,
  }) async {
    _isCategoryLoading = true;
    _categoryError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _analysisService.getCategoryDetail(categoria: categoria, mes: mes, anio: anio),
        _expenseService.getExpenses(mes: mes, anio: anio, categoria: categoria),
      ]);
      _categoryDetail = results[0] as CategoryDetail;
      _categoryTransactions = results[1] as List<ExpenseModel>;
    } catch (e) {
      _categoryError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> runSimulation(double amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _simulationResult = await _analysisService.simulatePurchase(amount);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSimulation() {
    _simulationResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> runSavingsProjection({
    required String categoria,
    required double gastoActual,
    required double gastoObjetivo,
  }) async {
    _isProjecting = true;
    _projectionError = null;
    _savingsProjection = null;
    notifyListeners();

    try {
      _savingsProjection = await _analysisService.getSavingsProjection(
        categoria: categoria,
        gastoActualMensual: gastoActual,
        gastoObjetivoMensual: gastoObjetivo,
      );
    } catch (e) {
      _projectionError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isProjecting = false;
      notifyListeners();
    }
  }

  void clearSavingsProjection() {
    _savingsProjection = null;
    _projectionError = null;
    notifyListeners();
  }
}

