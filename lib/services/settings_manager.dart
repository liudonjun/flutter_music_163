import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SettingsManager {
  static const String _apiSourceKey = 'api_source';
  static SettingsManager? _instance;
  static SharedPreferences? _prefs;

  SettingsManager._();

  static Future<SettingsManager> getInstance() async {
    if (_instance == null) {
      _instance = SettingsManager._();
      _prefs = await SharedPreferences.getInstance();
      // 初始化时从存储中恢复API源设置
      await _instance!._loadApiSource();
    }
    return _instance!;
  }

  Future<void> _loadApiSource() async {
    final savedUrl = _prefs?.getString(_apiSourceKey);
    if (savedUrl != null && ApiService.apiSources.containsValue(savedUrl)) {
      ApiService.setApiSource(savedUrl);
    }
  }

  Future<void> setApiSource(String url) async {
    await _prefs?.setString(_apiSourceKey, url);
    ApiService.setApiSource(url);
  }

  String getCurrentApiSource() {
    return ApiService.baseUrl;
  }

  String getCurrentSourceName() {
    return ApiService.getCurrentSourceName();
  }

  List<String> getAvailableApiSources() {
    return ApiService.apiSources.keys.toList();
  }

  String getApiUrlByName(String name) {
    return ApiService.apiSources[name] ?? ApiService.apiSources.values.first;
  }
}