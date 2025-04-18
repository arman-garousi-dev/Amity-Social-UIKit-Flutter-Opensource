import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/core/theme.dart';
import 'package:amity_uikit_beta_service/v4/social/globalfeed/amity_global_feed_component.dart';
import 'package:amity_uikit_beta_service/v4/social/user/feed/user_feed_empty_state_info.dart';
import 'package:amity_uikit_beta_service/v4/social/user/image_feed/element/user_image_feed_element.dart';
import 'package:amity_uikit_beta_service/v4/social/user/user_feed_empty_state.dart';
import 'package:amity_uikit_beta_service/v4/utils/config_provider.dart';
import 'package:amity_uikit_beta_service/v4/utils/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/user_image_feed_bloc.dart';

class UserImageFeedComponent extends NewBaseComponent {
  final String userId;

  late ScrollController scrollController;
  final AmityUserFollowInfo? userFollowInfo;

  UserImageFeedComponent({
    super.key,
    String? pageId,
    required this.userId,
    ScrollController? scrollController,
    this.userFollowInfo,
  }) : super(componentId: "user_image_feed") {
    if (scrollController != null) {
      this.scrollController = scrollController;
    } else {
      this.scrollController = ScrollController();
    }
  }

  @override
  Widget buildComponent(BuildContext context) {
    return BlocProvider<UserImageFeedBloc>(
      create: (context) =>
          UserImageFeedBloc(userId: userId, scrollController: scrollController),
      child: BlocBuilder<UserImageFeedBloc, UserImageFeedState>(
        builder: (context, state) {
          if (!state.isLoading && state.posts.isEmpty) {
            final UserFeedEmptyStateInfo info;
            if (userFollowInfo?.status == AmityFollowStatus.BLOCKED) {
              info = getEmptyStateInfo(UserFeedEmptyStateType.blocked);
            } else {
              info = getEmptyStateInfo(
                  state.emptyState ?? UserFeedEmptyStateType.empty);
            }
            return UserFeedEmptyState(info: info);
          } else if (state.posts.isEmpty && state.isLoading) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getSkeleton(theme, configProvider),
              ],
            );
          } else {
            return Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              color: theme.backgroundColor,
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: state.posts.length,
                    itemBuilder: (context, index) {
                      final post = state.posts[index];

                      return UserImageFeedElement(
                        post: post,
                      );
                    },
                  ),
                  if (state.isLoading && state.posts.isNotEmpty)
                    getSkeleton(theme, configProvider),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget getSkeleton(AmityThemeColor theme, ConfigProvider configProvider) {
    return Container(
      color: theme.backgroundColor,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(
            linearGradient: configProvider.getShimmerGradient(),
            child: ListView.separated(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) {
                return Divider(
                  color: theme.baseColorShade4,
                  thickness: 8,
                );
              },
              itemBuilder: (context, index) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      isLoading: true,
                      child: skeletonRow(),
                    ),
                  ],
                );
              },
              itemCount: 4,
            ),
          ),
        ],
      ),
    );
  }

  UserFeedEmptyStateInfo getEmptyStateInfo(UserFeedEmptyStateType type) {
    switch (type) {
      case UserFeedEmptyStateType.empty:
        return UserFeedEmptyStateInfo(
            "No photos yet", "", "assets/Icons/amity_ic_feed_empty.svg");
      case UserFeedEmptyStateType.blocked:
        return UserFeedEmptyStateInfo(
            "You've blocked this user",
            "Unblock to see their posts.",
            "assets/Icons/amity_ic_blocked_feed_empty_state.svg");
      case UserFeedEmptyStateType.private:
        return UserFeedEmptyStateInfo(
            "This account is private",
            "Follow this user to see their posts.",
            "assets/Icons/amity_ic_private_feed_empty_state.svg");
    }
  }
}
