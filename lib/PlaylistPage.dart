import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'PlaylistDetailPage.dart';
import 'SearchPage.dart';
import 'services/api_service.dart';
import 'widgets/mini_player.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List playlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
  }

  Future<void> fetchPlaylists() async {
    try {
      final fetchedPlaylists = await ApiService.getTopPlaylists();
      setState(() {
        playlists = fetchedPlaylists;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                        expandedHeight: 120.h,
                        pinned: true,
                        actions: [
                          IconButton(
                            icon: Icon(Icons.search,
                                color: Colors.white, size: 28.sp),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchPage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 8.w),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            '热门歌单',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          titlePadding:
                              EdgeInsets.only(left: 20.w, bottom: 16.h),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final playlist = playlists[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistDetailPage(
                                        id: playlist['id'].toString(),
                                        coverUrl: playlist['coverImgUrl'],
                                        name: playlist['name'],
                                      ),
                                    ),
                                  );
                                },
                                child: AppleMusicPlaylistCard(
                                  coverUrl: playlist['coverImgUrl'],
                                  name: playlist['name'],
                                  playCount: playlist['playCount'],
                                ),
                              );
                            },
                            childCount: playlists.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 20.h,
                          ),
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

class AppleMusicPlaylistCard extends StatelessWidget {
  final String coverUrl;
  final String name;
  final int playCount;

  const AppleMusicPlaylistCard({
    super.key,
    required this.coverUrl,
    required this.name,
    required this.playCount,
  });

  String _formatPlayCount(int count) {
    if (count > 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count > 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 48.sp,
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
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _formatPlayCount(playCount),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String coverUrl;
  final String name;
  final int playCount;

  const PlaylistCard({
    super.key,
    required this.coverUrl,
    required this.name,
    required this.playCount,
  });

  String _formatPlayCount(int count) {
    if (count > 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count > 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 5.h,
                right: 5.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 12.sp),
                      Text(
                        _formatPlayCount(playCount),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
