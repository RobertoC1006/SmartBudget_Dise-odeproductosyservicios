import 'package:flutter/material.dart';
import '../models/profile_summary_model.dart';
import '../services/profile_service.dart';

/// Estado del "Resumen personal" de la pantalla de Perfil (1A).
///
/// Una sola llamada (`GET /profile/summary`) alimenta metas activas, gastos
/// registrados, dinero ahorrado y SmartScore (+delta). "Días racha" no vive
/// aquí: es un placeholder visual en la pantalla.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileSummary? _summary;
  ProfileSummary? get summary => _summary;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _summary = await _profileService.getSummary();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
