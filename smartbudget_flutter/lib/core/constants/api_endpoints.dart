import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8002/api';
    }
    try {
      if (Platform.isAndroid) {
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
  static String contributeGoal(int id) => '/goals/$id/contribute';

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
}
