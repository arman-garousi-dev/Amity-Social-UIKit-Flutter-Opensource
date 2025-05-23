import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/styles.dart';
import 'package:amity_uikit_beta_service/v4/core/theme.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:amity_uikit_beta_service/v4/core/user_avatar.dart';
import 'package:amity_uikit_beta_service/v4/social/post/amity_post_content_component.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_display_name.dart';
import 'package:amity_uikit_beta_service/v4/social/post/featured_badge.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post_composer_page/post_composer_model.dart';
import 'package:amity_uikit_beta_service/v4/social/post_composer_page/post_composer_page.dart';
import 'package:amity_uikit_beta_service/v4/social/user/profile/amity_user_profile_page.dart';
import 'package:amity_uikit_beta_service/v4/utils/user_image.dart';
import 'package:amity_uikit_beta_service/viewmodel/edit_post_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../core/toast/amity_uikit_toast.dart';

class AmityPostHeader extends StatelessWidget {
  final AmityPost post;
  final bool isShowOption;
  final AmityThemeColor theme;
  final AmityPostCategory category;
  final bool hideTarget;
  final AmityPostAction? action;

  const AmityPostHeader({
    super.key,
    required this.post,
    this.isShowOption = true,
    required this.theme,
    required this.category,
    required this.hideTarget,
    this.action,
  });

  
  void _showToast(BuildContext context, String message, AmityToastIcon icon) {
    context
        .read<AmityToastBloc>()
        .add(AmityToastShort(message: message, icon: icon));
  }

  bool showClosePollOption(AmityPost post) {
    if (post.feedType == AmityFeedType.PUBLISHED &&
        post.type == AmityDataType.TEXT) {
      final firstChild =
          post.children?.isNotEmpty == true ? post.children!.first : null;

      if (firstChild != null) {
        final data = firstChild.data;

        if (data != null && data is PollData && data.poll?.isClose == false) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (category == AmityPostCategory.announcement ||
            category == AmityPostCategory.announcementAndPin ||
            category == AmityPostCategory.globalFeatured)
          Row(
            children: [
              FeaturedBadge(text: "Featured"),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AmityUserProfilePage(
                      userId: post.postedUserId ?? "",
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.only(
                    top: 8, left: 12, right: 4, bottom: 8),
                child: AmityUserAvatar(
                  avatarUrl: post.postedUser?.avatarUrl,
                  displayName: post.postedUser?.displayName ?? "",
                  isDeletedUser: post.postedUser?.isDeleted ?? false,
                  characterTextStyle: AmityTextStyle.titleBold(Colors.white),
                  avatarSize: const Size(32, 32),
                ),
              ),
            ),
            Expanded(
                child: PostDisplayName(
                    post: post, theme: theme, hideTarget: hideTarget)),
            if (category == AmityPostCategory.pin ||
                category == AmityPostCategory.announcementAndPin) ...[
              Container(
                  width: 33,
                  height: 33,
                  padding: const EdgeInsets.only(
                      top: 4, left: 2, right: 2, bottom: 8),
                  child: SizedBox(
                      width: 20,
                      child: SvgPicture.asset(
                        'assets/Icons/amity_ic_pin_badge.svg',
                        package: 'amity_uikit_beta_service',
                        width: 20,
                        height: 20,
                      )))
            ],
            GestureDetector(
              onTap: () => showPostAction(context, post),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.only(
                    top: 8, left: 4, right: 16, bottom: 8),
                child: isShowOption ? getPostOptionIcon() : Container(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget getPostOptionIcon() {
    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SvgPicture.asset(
        'assets/Icons/amity_ic_post_item_option.svg',
        package: 'amity_uikit_beta_service',
        width: 16,
        height: 12,
      ),
    );
  }

  void showPostAction(BuildContext context, AmityPost post) async {
    final currentUserId = AmityCoreClient.getUserId();

    var isModerator = false;

    var postTarget = post.target;
    if (postTarget is CommunityTarget) {
      var roles = await AmitySocialClient.newCommunityRepository()
          .getCurrentUserRoles(postTarget.targetCommunityId ?? "");

      if (roles != null &&
          (roles.contains("moderator") ||
              roles.contains("community-moderator"))) {
        isModerator = true;
      }
    }

    if (post.postedUserId == currentUserId) {
      showPostOwnerAction(context, post, theme, isModerator);
    } else {
      showPostGeneralAction(context, post, isModerator);
    }
  }

  void showPostGeneralAction(
      BuildContext context, AmityPost post, bool isModerator) {
    onReport() => {
          context.read<PostItemBloc>().add(PostItemFlag(
              post: post, toastBloc: context.read<AmityToastBloc>()))
        };
    onUnReport() => {
          context.read<PostItemBloc>().add(PostItemUnFlag(
              post: post, toastBloc: context.read<AmityToastBloc>()))
        };

    onDelete() {
      context
          .read<PostItemBloc>()
          .add(PostItemDelete(post: post, action: action));
    }

    double height = 0;
    double baseHeight = 80;
    double itemHeight = 48;
    if (isModerator) {
      itemHeight += 48;
    }
    height = baseHeight + itemHeight;

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 36,
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFA5A9B5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (!post.isFlaggedByMe)
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onReport();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 2),
                                child: SvgPicture.asset(
                                  'assets/Icons/amity_ic_flag.svg',
                                  package: 'amity_uikit_beta_service',
                                  width: 24,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Report post',
                                style: TextStyle(
                                  color: Color(0xFF292B32),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onUnReport();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 2),
                                child: SvgPicture.asset(
                                  'assets/Icons/amity_ic_flag.svg',
                                  package: 'amity_uikit_beta_service',
                                  width: 24,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Unreport post',
                                style: TextStyle(
                                  color: Color(0xFF292B32),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                if (isModerator) _getDeletePost(context, post, onDelete)
              ],
            ),
          );
        });
  }

  void showPostOwnerAction(BuildContext context, AmityPost post,
      AmityThemeColor theme, bool isModerator) {
    final editOption = AmityPostComposerOptions.editOptions(post: post);

    onEdit() => {
          Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => ChangeNotifierProvider<EditPostVM>(
                  create: (context) => EditPostVM(),
                  child: AmityPostComposerPage(options: editOption))))
        };

    onClosePoll(String pollId) => {
          AmitySocialClient.newPollRepository()
              .closePoll(pollId: pollId)
              .then((value) {
            //success
          }).onError((error, stackTrace) {
            _showToast(
                context, "Oops, something went wrong", AmityToastIcon.warning);
          })
        };

    onDelete() {
      AmitySocialClient.newPostRepository()
          .deletePost(postId: post.postId!)
          .then((value) {
        context
            .read<PostItemBloc>()
            .add(PostItemDelete(post: post, action: action));
        //success
      }).onError((error, stackTrace) {
        _showToast(context, "Failed to delete post. Please try again.",
            AmityToastIcon.warning);
      });
    }

    double height = 0;
    double baseHeight = 80;
    double itemsHeight = 96;
    height = baseHeight + itemsHeight;

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 36,
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFA5A9B5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.type == AmityDataType.TEXT &&
                    (post.children == null ||
                        post.children!.first.type != AmityDataType.POLL))
                  GestureDetector(
                    onTap: () {
                      if (category == AmityPostCategory.globalFeatured) {
                        Navigator.pop(context);

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CupertinoAlertDialog(
                              title: const Text("Edit globally featured post?"),
                              content: const Text(
                                  "The post you're editing has been featured globally. If you edit your post, it would need to be re-approved, and will no longer be globally featured."),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Cancel",
                                      style: TextStyle(
                                        color: Color(0xFF007AFF),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: Text(
                                    "Edit",
                                    style: TextStyle(
                                      color: theme.alertColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onEdit();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        Navigator.pop(context);
                        onEdit();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: SvgPicture.asset(
                              'assets/Icons/amity_ic_edit_comment.svg',
                              package: 'amity_uikit_beta_service',
                              width: 24,
                              height: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit post',
                            style: TextStyle(
                              color: Color(0xFF292B32),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showClosePollOption(post))
                  _getClosePoll(context, post, onClosePoll),
                _getDeletePost(context, post, onDelete),
              ],
            ),
          );
        });
  }

  Widget _getClosePoll(
      BuildContext context, AmityPost post, Function onClosePoll) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        final pollId = (post.children!.first.data as PollData).pollId;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text("Close poll"),
              content: const Text(
                  "This poll duration you've set will be ignored and your poll will be closed immediately."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Cancel",
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      )),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(
                    "Close poll",
                    style: TextStyle(
                      color: theme.alertColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClosePoll(pollId);
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: SvgPicture.asset(
                'assets/Icons/amity_ic_create_poll_button.svg',
                package: 'amity_uikit_beta_service',
                width: 24,
                height: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Close poll',
              style: TextStyle(
                color: Color(0xFF292B32),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDeletePost(
      BuildContext context, AmityPost post, Function onDelete) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text("Delete post"),
              content: const Text("This post will be permanently deleted."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Cancel",
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      )),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: theme.alertColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: SvgPicture.asset(
                'assets/Icons/amity_ic_delete.svg',
                package: 'amity_uikit_beta_service',
                width: 24,
                height: 20,
                colorFilter:
                    ColorFilter.mode(theme.alertColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete post',
              style: TextStyle(
                color: theme.alertColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
