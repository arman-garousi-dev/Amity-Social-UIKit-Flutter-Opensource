import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/social/globalfeed/amity_empty_newsfeed_component.dart';
import 'package:amity_uikit_beta_service/v4/social/globalfeed/bloc/global_feed_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/amity_post_content_component.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/story/target/amity_story_tab_component.dart';
import 'package:amity_uikit_beta_service/v4/social/story/target/amity_story_tab_component_type.dart';
import 'package:amity_uikit_beta_service/v4/utils/shimmer.dart';
import 'package:amity_uikit_beta_service/v4/utils/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AmityGlobalFeedComponent extends NewBaseComponent {
  AmityGlobalFeedComponent({Key? key, String? pageId}) : super(key: key, pageId: pageId, componentId: 'global_feed_component');

  List<String> viewedPost = [];

  @override
  Widget buildComponent(BuildContext context) {
    final scrollController = ScrollController();
    context.read<GlobalFeedBloc>().add(GlobalFeedInit());
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        context.read<GlobalFeedBloc>().add(GlobalFeedFetch());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<GlobalFeedBloc>().add(GlobalFeedFetch());
    });

    return Container(
      color: theme.backgroundColor,
      child: BlocBuilder<GlobalFeedBloc, GlobalFeedState>(builder: (context, state) {
        if (state.isFetching && state.list.isEmpty) {
          viewedPost = [];
          return skeletonList();
        } else {
          return BaseComponent(
              child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: theme.baseColorShade4),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: AmityStoryTabComponent(
                    type: GlobalFeedStoryTab(),
                  ),
                ),
                if (state.list.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<GlobalFeedBloc>().add(GlobalFeedInit());
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: state.list.length,
                        itemBuilder: (context, index) {
                          final amityPost = state.list[index];

                          if (((amityPost.children?.isNotEmpty ?? false) && (amityPost.children!.first.type == AmityDataType.FILE || amityPost.children!.first.type == AmityDataType.POLL || amityPost.children!.first.type == AmityDataType.LIVESTREAM)) || (amityPost.isDeleted ?? false)) {
                            return Container();
                          } else {
                            return BlocProvider(
                              create: (context) => PostItemBloc(),
                              child: VisibilityDetector(
                                key: Key(amityPost.postId ?? ''),
                                onVisibilityChanged: (VisibilityInfo info) {
                                  final visiblePercentage = info.visibleFraction * 100;
                                  if (visiblePercentage > 60) {
                                    checkVisibilityAndMarkSeen(amityPost, visiblePercentage);
                                  }
                                },
                                child: Column(
                                  children: [
                                    AmityPostContentComponent(
                                      style: AmityPostContentComponentStyle.feed,
                                      post: amityPost,
                                      action: AmityPostAction(
                                        onAddReaction: (String) {},
                                        onRemoveReaction: (String) {},
                                        onPostDeleted: (AmityPost post) {
                                          context.read<GlobalFeedBloc>().add(GlobalFeedReloadThePost(post: post));
                                        },
                                        onPostUpdated: (post) {},
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        padding: const EdgeInsets.only(top: 8),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: theme.backgroundColor,
                      alignment: Alignment.center,
                      child: state.isFetching ? const CircularProgressIndicator() : AmityEmptyNewsFeedComponent(elementId: "amity_empty_newsfeed_component"),
                    ),
                  ),
                if (state.isFetching && state.list.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  )
              ],
            ),
          ));
        }
      }),
    );
  }

  Widget skeletonList() {
    return Container(
      decoration: BoxDecoration(color: theme.backgroundColor),
      child: Column(children: [
        Container(
          color: theme.baseColorShade4,
          height: 8,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.topCenter,
            child: Shimmer(
              linearGradient: configProvider.getShimmerGradient(),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) {
                  return Divider(
                    color: theme.baseColorShade4,
                    thickness: 8,
                    height: 24,
                  );
                },
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          isLoading: true,
                          child: skeletonRow(),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: 4,
              ),
            ),
          ),
        )
      ]),
    );
  }

  Widget skeletonRow() {
    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 60,
                  padding: const EdgeInsets.only(top: 12, left: 0, right: 8, bottom: 8),
                  child: const SkeletonImage(
                    height: 40,
                    width: 40,
                    borderRadius: 40,
                  ),
                ),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 6.0),
                  SkeletonText(width: 120),
                  SizedBox(height: 12.0),
                  SkeletonText(width: 88),
                ]),
              ],
            ),
            const SizedBox(height: 14.0),
            const SkeletonText(width: 240),
            const SizedBox(height: 12.0),
            const SkeletonText(width: 297),
            const SizedBox(height: 12.0),
            const SkeletonText(width: 180),
          ],
        ),
      ),
    );
  }

  void checkVisibilityAndMarkSeen(AmityPost post, double visiblePercentage) {
    if (visiblePercentage > 60 && !viewedPost.contains(post.postId)) {
      viewedPost.add(post.postId!);
      post.analytics().markPostAsViewed();
    }
  }
}
