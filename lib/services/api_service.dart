import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String _baseUrl = 'http://api.ygking.cn:3000';

  static const Map<String, String> apiSources = {
    '线上': 'http://api.ygking.cn:3000',
    '本地服务器': 'http://192.168.1.28:3000',
  };

  static String get baseUrl => _baseUrl;

  static void setApiSource(String url) {
    _baseUrl = url;
  }

  static String getCurrentSourceName() {
    for (var entry in apiSources.entries) {
      if (entry.value == _baseUrl) {
        return entry.key;
      }
    }
    return '未知源';
  }

  static Future<Map<String, dynamic>> _makeRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求错误: $e');
    }
  }

  static Future<List<dynamic>> getTopPlaylists({String order = 'hot'}) async {
    final data = await _makeRequest('/top/playlist?order=$order');
    return data['playlists'] ?? [];
  }

  static Future<Map<String, dynamic>> getPlaylistDetail(String id) async {
    final data = await _makeRequest('/playlist/detail?id=$id');
    return data['playlist'] ?? {};
  }

  static Future<String> getLyrics(String songId) async {
    final data = await _makeRequest('/lyric?id=$songId');
    return data['lrc']['lyric'] ?? '';
  }

  static Future<Map<String, dynamic>> getSongDetail(String songId) async {
    final data = await _makeRequest('/song/detail?ids=$songId');
    if (data['songs'] != null && data['songs'].isNotEmpty) {
      return data['songs'][0];
    }
    return {};
  }

  static Future<String?> getSongUrl(String songId) async {
    final data = await _makeRequest('/song/url?id=$songId');
    final List<dynamic> dataList = data['data'] ?? [];
    if (dataList.isNotEmpty) {
      final songInfo = dataList[0] as Map<String, dynamic>;
      return songInfo['url'] as String?;
    }
    return null;
  }

  static Future<Map<String, dynamic>> search(String keywords) async {
    final data =
        await _makeRequest('/search?keywords=${Uri.encodeComponent(keywords)}');
    return data;
  }
}
