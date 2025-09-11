import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_163/LyricPage.dart';
import 'services/api_service.dart';
import 'services/global_player_manager.dart';
import 'widgets/mini_player.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String keywords) async {
    if (keywords.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final result = await ApiService.search(keywords.trim());
      setState(() {
        _searchResults = result['result']['songs'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('搜索失败: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 头部搜索区域
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部导航
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '搜索',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 搜索框
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.white, fontSize: 20.sp),
                      decoration: InputDecoration(
                        hintText: '歌曲、艺术家或专辑',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 20.sp,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 22.sp,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                    _hasSearched = false;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.grey[500],
                                    size: 22.sp,
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero, // 去掉额外 padding
                      ),
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 搜索结果区域
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.red),
                          SizedBox(height: 16.h),
                          Text(
                            '正在搜索...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : !_hasSearched
                      ? _buildSuggestions()
                      : _searchResults.isEmpty
                          ? _buildNoResults()
                          : _buildSearchResults(),
            ),

            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            '热门搜索',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              '周杰伦',
              '邓紫棋',
              '林俊杰',
              '陈奕迅',
              '薛之谦',
              '毛不易',
              '李荣浩',
              '张学友',
            ].map((keyword) => _buildSuggestionChip(keyword)).toList(),
          ),
          SizedBox(height: 40.h),
          Text(
            '最近搜索',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey[500], size: 24.sp),
                SizedBox(width: 16.w),
                Text(
                  '暂无搜索历史',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String keyword) {
    return GestureDetector(
      onTap: () {
        _searchController.text = keyword;
        _performSearch(keyword);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          keyword,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Icon(
              Icons.music_off_outlined,
              color: Colors.grey[600],
              size: 50.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '未找到"${_searchController.text}"',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '请尝试搜索其他内容',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                Text(
                  '歌曲 (${_searchResults.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _searchResults[index];
                final artists = (song['artists'] as List?)
                        ?.map((artist) => artist['name'])
                        .join(', ') ??
                    '未知艺术家';

                return AppleMusicSearchTile(
                  index: index + 1,
                  songName: song['name'] ?? '未知歌曲',
                  artistName: artists,
                  albumArt: song['album']?['picUrl'] ?? '',
                  onTap: () {
                    GlobalPlayerManager().playPlaylist(_searchResults, index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LyricPage(
                          songId: song['id'].toString(),
                          songs: _searchResults,
                          currentIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: _searchResults.length,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: 100.h),
        ),
      ],
    );
  }

  String _formatDuration(int duration) {
    final minutes = (duration / 1000 / 60).floor();
    final seconds = ((duration / 1000) % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AppleMusicSearchTile extends StatelessWidget {
  final int index;
  final String songName;
  final String artistName;
  final String albumArt;
  final VoidCallback onTap;

  const AppleMusicSearchTile({
    super.key,
    required this.index,
    required this.songName,
    required this.artistName,
    required this.albumArt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Row(
              children: [
                // 排序数字
                Container(
                  width: 28.w,
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // 专辑封面
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: albumArt.isNotEmpty
                        ? Image.network(
                            albumArt,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.music_note,
                                color: Colors.grey[500],
                                size: 24.sp,
                              );
                            },
                          )
                        : Icon(
                            Icons.music_note,
                            color: Colors.grey[500],
                            size: 24.sp,
                          ),
                  ),
                ),
                SizedBox(width: 16.w),

                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        artistName,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 17.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 更多选项
                Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.more_horiz,
                    color: Colors.grey[500],
                    size: 24.sp,
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
