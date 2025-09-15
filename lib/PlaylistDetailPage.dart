import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_163/LyricPage.dart';
import 'services/api_service.dart';
import 'services/global_player_manager.dart';
import 'widgets/mini_player.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String id;
  final String coverUrl;
  final String name;

  const PlaylistDetailPage({
    super.key,
    required this.id,
    required this.coverUrl,
    required this.name,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  Map<String, dynamic> playlistDetail = {};
  List songs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 设置错误回调
    GlobalPlayerManager().onError = (String errorMessage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
    fetchPlaylistDetail();
  }

  Future<void> fetchPlaylistDetail() async {
    try {
      final detail = await ApiService.getPlaylistDetail(widget.id);
      setState(() {
        playlistDetail = detail;
        songs = playlistDetail['tracks'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching playlist detail: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDuration(int duration) {
    final minutes = (duration / 1000 / 60).floor();
    final seconds = ((duration / 1000) % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.black,
                        expandedHeight: 400.h,
                        pinned: true,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 24.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                widget.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                      size: 80.sp,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.8),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20.h,
                                left: 20.w,
                                right: 20.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 38.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Text(
                                          '${songs.length} 首歌曲',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 30.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 64.w,
                                          height: 64.w,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(32.r),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 36.sp,
                                            ),
                                            onPressed: () {
                                              if (songs.isNotEmpty) {
                                                GlobalPlayerManager()
                                                    .playPlaylist(songs, 0);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = songs[index];
                            final artists = (song['ar'] as List)
                                .map((artist) => artist['name'])
                                .join(', ');

                            return AppleMusicSongTile(
                              index: index,
                              songName: song['name'],
                              artistName: artists,
                              albumName: song['al']['name'],
                              duration: _formatDuration(song['dt']),
                              onTap: () {
                                GlobalPlayerManager()
                                    .playPlaylist(songs, index);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LyricPage(
                                      songId: song['id'].toString(),
                                      songs: songs,
                                      currentIndex: index,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: songs.length,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: 100.h),
                      ),
                    ],
                  ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class AppleMusicSongTile extends StatelessWidget {
  final int index;
  final String songName;
  final String artistName;
  final String albumName;
  final String duration;
  final VoidCallback onTap;

  const AppleMusicSongTile({
    super.key,
    required this.index,
    required this.songName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$artistName - $albumName',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 25.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
