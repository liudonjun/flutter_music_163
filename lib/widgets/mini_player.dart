import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_163/LyricPage.dart';
import 'package:music_163/services/global_player_manager.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GlobalPlayerManager(),
      builder: (context, child) {
        final player = GlobalPlayerManager();

        if (player.songTitle.isEmpty) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          child: Container(
            height: 100.h,
            color: Colors.grey[900],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LyricPage(
                        songId: player.currentSongId,
                        songs: player.playlist,
                        currentIndex: player.currentIndex,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      // 专辑封面
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                          ),
                          child: player.albumArt.isNotEmpty
                              ? Image.network(
                                  player.albumArt,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                      size: 32.sp,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                  size: 32.sp,
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // 歌曲信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              player.songTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              player.artistName,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 20.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 控制按钮
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: player.hasPrevious
                              ? Colors.white
                              : Colors.white30,
                          size: 30.sp,
                        ),
                        onPressed:
                            player.hasPrevious ? player.playPrevious : null,
                      ),

                      IconButton(
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 34.sp,
                        ),
                        onPressed: () {
                          if (player.isPlaying) {
                            player.pause();
                          } else {
                            player.play();
                          }
                        },
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: player.hasNext ? Colors.white : Colors.white30,
                          size: 30.sp,
                        ),
                        onPressed: player.hasNext ? player.playNext : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
