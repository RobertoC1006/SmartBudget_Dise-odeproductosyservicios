import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../models/smartscore_model.dart';
import '../services/analysis_service.dart';
import '../services/smartscore_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();
  final SmartScoreService _smartScoreService = SmartScoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, double>? _expensesByCategory;
  Map<String, double>? get expensesByCategory => _expensesByCategory;

  List<SmartScoreSnapshotModel> _scoreHistory = [];
  List<SmartScoreSnapshotModel> get scoreHistory => _scoreHistory;

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
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
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

