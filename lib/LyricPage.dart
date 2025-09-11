import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/api_service.dart';
import 'services/global_player_manager.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class LyricPage extends StatefulWidget {
  final String songId;
  final List<dynamic> songs;
  final int currentIndex;

  const LyricPage({
    super.key,
    required this.songId,
    required this.songs,
    required this.currentIndex,
  });

  @override
  State<LyricPage> createState() => _LyricPageState();
}

class _LyricPageState extends State<LyricPage> {
  final GlobalPlayerManager _playerManager = GlobalPlayerManager();
  List<LyricLine> _lyrics = [];
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final PageController _pageController = PageController(initialPage: 0);
  String _lastSongId = '';

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    _playerManager.addListener(_onPlayerStateChanged);

    _pageController.addListener(() {
      if (_pageController.page?.round() == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrent();
        });
      }
    });
  }

  void _onPlayerStateChanged() {
    // Check if song has changed
    if (_playerManager.currentSongId != _lastSongId &&
        _playerManager.currentSongId.isNotEmpty) {
      _lastSongId = _playerManager.currentSongId;
      _fetchLyrics();
    }
    _updateLyricIndex(_playerManager.position);
  }

  Future<void> _fetchLyrics() async {
    try {
      // Use current song ID from player manager if available, otherwise fall back to widget parameter
      final songId = _playerManager.currentSongId.isNotEmpty
          ? _playerManager.currentSongId
          : widget.songs[widget.currentIndex]['id'].toString();

      final lrcText = await ApiService.getLyrics(songId);

      final lines = lrcText.split('\n');
      final parsed = <LyricLine>[];
      final reg = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)');

      for (var line in lines) {
        final match = reg.firstMatch(line);
        if (match != null) {
          final min = int.parse(match.group(1)!);
          final sec = int.parse(match.group(2)!);
          final ms = match.group(3) != null
              ? int.parse(match.group(3)!.padRight(3, '0'))
              : 0;
          final text = match.group(4)!.trim();
          if (text.isNotEmpty) {
            parsed.add(LyricLine(
              time: Duration(minutes: min, seconds: sec, milliseconds: ms),
              text: text,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _lyrics = parsed;
          _currentIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching lyrics: $e');
    }
  }

  void _updateLyricIndex(Duration pos) {
    for (int i = 0; i < _lyrics.length; i++) {
      if (i < _lyrics.length - 1) {
        if (pos >= _lyrics[i].time && pos < _lyrics[i + 1].time) {
          if (_currentIndex != i) {
            if (mounted) {
              setState(() {
                _currentIndex = i;
              });
              _scrollToCurrent();
            }
          }
          break;
        }
      } else {
        if (pos >= _lyrics[i].time) {
          if (_currentIndex != i) {
            if (mounted) {
              setState(() {
                _currentIndex = i;
              });
              _scrollToCurrent();
            }
          }
        }
      }
    }
  }

  void _scrollToCurrent() {
    if (_scrollController.hasClients && _lyrics.isNotEmpty) {
      const itemHeight = 80.0;
      final targetOffset = _currentIndex * itemHeight;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _playerManager.removeListener(_onPlayerStateChanged);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _playerManager,
      builder: (context, child) {
        final progress = _playerManager.duration.inMilliseconds > 0
            ? _playerManager.position.inMilliseconds /
                _playerManager.duration.inMilliseconds
            : 0.0;

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon:
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            decoration: _playerManager.albumArt.isNotEmpty
                ? BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_playerManager.albumArt),
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        children: [
                          _buildAlbumArtPage(),
                          _buildLyricsPage(),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(64.w),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                              thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 12.r),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 40.r),
                              trackHeight: 6.h,
                              trackShape: const RoundedRectSliderTrackShape(),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                final newPos = _playerManager.duration * value;
                                _playerManager.seek(newPos);
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_playerManager.position),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  _formatDuration(_playerManager.duration),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 64.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                iconSize: 88.w,
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.white),
                                onPressed: _playerManager.playPrevious,
                              ),
                              Container(
                                width: 144.w,
                                height: 144.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(72.r),
                                ),
                                child: IconButton(
                                  iconSize: 72.w,
                                  icon: Icon(
                                    _playerManager.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    if (_playerManager.isPlaying) {
                                      _playerManager.pause();
                                    } else {
                                      _playerManager.play();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                iconSize: 88.w,
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.white),
                                onPressed: _playerManager.playNext,
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArtPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CD 封面
        Container(
          width: 600.w,
          height: 600.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(150.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: _playerManager.albumArt.isNotEmpty
                ? Image.network(_playerManager.albumArt, fit: BoxFit.cover)
                : Container(color: Colors.grey[800]),
          ),
        ),

        SizedBox(height: 32.h),

        // 歌曲标题
        Text(_playerManager.songTitle,
            style: TextStyle(color: Colors.white, fontSize: 48.sp)),
        Text(_playerManager.artistName,
            style: TextStyle(color: Colors.white70, fontSize: 32.sp)),

        SizedBox(height: 24.h),

        // 当前歌词显示
        _lyrics.isEmpty
            ? const SizedBox.shrink()
            : Container(
                height: 80.h,
                padding: EdgeInsets.symmetric(horizontal: 80.w),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _lyrics.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          _lyrics[_currentIndex].text,
                          key: ValueKey(_currentIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 50.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
      ],
    );
  }

  Widget _buildLyricsPage() {
    return _lyrics.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.15, 0.85, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _lyrics.length,
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height / 2 - 100.h,
              ),
              itemBuilder: (context, index) {
                final line = _lyrics[index];
                final isActive = index == _currentIndex;
                final distance = (index - _currentIndex).abs();
                final opacity = _calculateOpacity(distance);
                final blur = _calculateBlur(distance);
                final scale = _calculateScale(distance);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.center,
                  height: 80,
                  padding: EdgeInsets.symmetric(horizontal: 80.w),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: isActive ? 60.sp : 44.sp,
                      color: Colors.white.withOpacity(opacity),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      height: 1.3,
                      letterSpacing: isActive ? 0.5 : 0.0,
                    ),
                    child: Transform.scale(
                      scale: scale,
                      child: ImageFiltered(
                        imageFilter:
                            ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  double _calculateOpacity(int distance) {
    if (distance == 0) return 1.0;
    if (distance == 1) return 0.7;
    if (distance == 2) return 0.4;
    if (distance == 3) return 0.2;
    return 0.1;
  }

  double _calculateBlur(int distance) {
    if (distance == 0) return 0.0;
    if (distance == 1) return 0.3;
    if (distance == 2) return 0.8;
    return 1.5;
  }

  double _calculateScale(int distance) {
    if (distance == 0) return 1.0;
    if (distance == 1) return 0.95;
    if (distance == 2) return 0.9;
    return 0.85;
  }
}
