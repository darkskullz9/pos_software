import 'package:flutter/foundation.dart';

import '../models/app_settings_model.dart';
import 'database_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService() {
    loadSettings();
  }

  final DatabaseService _databaseService = DatabaseService.instance;

  AppSettingsModel _settings = AppSettingsModel.defaults();
  bool _isLoading = false;

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settingsMap = await _databaseService.getSettings();

      if (settingsMap.isEmpty) {
        _settings = AppSettingsModel.defaults();
        await saveSettings(_settings);
      } else {
        _settings = AppSettingsModel.fromSettingsMap(settingsMap);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    await _databaseService.saveSettings(_settings.toSettingsMap());
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await saveSettings(AppSettingsModel.defaults());
  }
}
