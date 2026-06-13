import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  /// IP del servidor, configurable al compilar para probar en un celular real:
  /// flutter build apk --dart-define=API_HOST=192.168.1.14
  static const String _apiHost = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_apiHost.isNotEmpty) {
      return 'http://$_apiHost:8002/api';
    }
    if (kIsWeb) {
      return 'http://localhost:8002/api';
    }
    try {
      if (Platform.isAndroid) {
        // Emulador de Android: 10.0.2.2 apunta al localhost de la PC
        return 'http://10.0.2.2:8002/api';
      }
    } catch (_) {
      // In case Platform check is unsupported on a target platform
    }
    return 'http://localhost:8002/api';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String updateMe = '/auth/me';

  // Budgets
  static const String currentBudget = '/budgets/current';
  static const String createBudget = '/budgets/';
  static const String addIncome = '/budgets/income';

  // Expenses
  static const String expenses = '/expenses/';
  static const String scanExpense = '/expenses/scan';
  static const String expensesSummary = '/expenses/summary';

  // Goals
  static const String goals = '/goals/';
  static String goalById(int id) => '/goals/$id';
  static String contributeGoal(int id) => '/goals/$id/contribute';
  static String contributionsGoal(int id) => '/goals/$id/contributions';

  // Alerts
  static const String alerts = '/alerts/';
  static const String generateAlerts = '/alerts/generate';
  static String readAlert(int id) => '/alerts/$id/read';

  // SmartScore
  static const String smartScore = '/smartscore/';
  static const String smartScoreSnapshot = '/smartscore/snapshot';
  static const String smartScoreHistory = '/smartscore/history';

  // Simulator
  static const String simulate = '/simulator/';
  static const String savingsProjection = '/simulator/savings-projection/';
}
