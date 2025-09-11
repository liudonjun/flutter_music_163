import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'api_service.dart';

class GlobalPlayerManager extends ChangeNotifier {
  static final GlobalPlayerManager _instance = GlobalPlayerManager._internal();
  factory GlobalPlayerManager() => _instance;
  GlobalPlayerManager._internal();

  final _player = AudioPlayer();
  
  // 播放状态
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // 歌曲信息
  String _songTitle = "";
  String _artistName = "";
  String _albumArt = "";
  String _currentSongId = "";
  
  // 播放列表
  List<dynamic> _playlist = [];
  int _currentIndex = 0;
  
  // 监听器
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  String get songTitle => _songTitle;
  String get artistName => _artistName;
  String get albumArt => _albumArt;
  String get currentSongId => _currentSongId;
  List<dynamic> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;
  
  double get progress {
    if (_duration.inMilliseconds > 0) {
      return _position.inMilliseconds / _duration.inMilliseconds;
    }
    return 0.0;
  }

  bool get hasPrevious => _playlist.isNotEmpty;
  bool get hasNext => _playlist.isNotEmpty;

  void _initListeners() {
    _positionSubscription = _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _playingSubscription = _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });
  }

  void _onSongCompleted() {
    // 播放完毕，自动下一首
    if (_currentIndex < _playlist.length - 1) {
      // 不是最后一首，播放下一首
      playNext();
    } else {
      // 最后一首，循环到第一首
      _currentIndex = 0;
      _playCurrentSong();
    }
  }

  Future<void> playPlaylist(List<dynamic> songs, int index) async {
    _playlist = songs;
    _currentIndex = index;
    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length) return;

    try {
      final song = _playlist[_currentIndex];
      final songId = song['id'].toString();
      
      _currentSongId = songId;
      
      // 获取歌曲详情
      final songDetail = await ApiService.getSongDetail(songId);
      _songTitle = songDetail['name'] ?? 'Unknown';
      _artistName = songDetail['ar']?.isNotEmpty == true
          ? songDetail['ar'][0]['name']
          : 'Unknown Artist';
      _albumArt = songDetail['al']['picUrl'] ?? '';
      
      // 获取播放URL
      final url = await ApiService.getSongUrl(songId);
      if (url == null) throw Exception('歌曲 URL 不可用');
      
      debugPrint('播放URL: $url');
      
      // 配置音频会话
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      
      await _player.setUrl(url);
      
      // 初始化监听器（只在第一次时）
      if (_positionSubscription == null) {
        _initListeners();
      }
      
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('播放歌曲失败: $e');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> playPrevious() async {
    if (_playlist.isNotEmpty) {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        // 第一首，循环到最后一首
        _currentIndex = _playlist.length - 1;
      }
      await _playCurrentSong();
    }
  }

  Future<void> playNext() async {
    if (_playlist.isNotEmpty) {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else {
        // 最后一首，循环到第一首
        _currentIndex = 0;
      }
      await _playCurrentSong();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}