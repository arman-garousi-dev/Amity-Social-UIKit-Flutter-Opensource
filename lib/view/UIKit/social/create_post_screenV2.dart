import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/components/theme_config.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/posts/post_cpmponent.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_feed_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_member_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/create_postV2_viewmodel.dart';
// import 'package:amity_uikit_beta_service/viewmodel/create_post_viewmodel.dart';
// import 'package:amity_uikit_beta_service/viewmodel/media_viewmodel.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../social/global_feed.dart';

class AmityCreatePostV2Screen extends StatefulWidget {
  final AmityCommunity? community;
  final AmityUser? amityUser;
  final bool isFromPostToPage;
  final FeedType? feedType;

  const AmityCreatePostV2Screen({
    super.key,
    this.community,
    this.amityUser,
    this.isFromPostToPage = false,
    this.feedType,
  });

  @override
  State<AmityCreatePostV2Screen> createState() =>
      _AmityCreatePostV2ScreenState();
}

class _AmityCreatePostV2ScreenState extends State<AmityCreatePostV2Screen> {
  bool hasContent = true;

  @override
  void initState() {
    Provider.of<CreatePostVMV2>(context, listen: false).inits();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tappablePostAsButton = widget.feedType == FeedType.community &&
        widget.community != null &&
        widget.community!.communityId != null &&
        AmityCoreClient.hasPermission(AmityPermission.EDIT_COMMUNITY_POST)
            .atCommunity(widget.community!.communityId!)
            .check();

    return Consumer<CreatePostVMV2>(builder: (consumerContext, vm, _) {
      return ThemeConfig(
        child: Scaffold(
          backgroundColor: Provider.of<AmityUIConfiguration>(context)
              .appColors
              .baseBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.community != null
                  ? widget.community?.displayName ?? "Community"
                  : "My Feed",
              style: Provider.of<AmityUIConfiguration>(context)
                  .titleTextStyle
                  .copyWith(
                      color: Provider.of<AmityUIConfiguration>(context)
                          .appColors
                          .base),
            ),
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  color: Provider.of<AmityUIConfiguration>(context)
                      .appColors
                      .base),
              onPressed: () {
                if (hasContent) {
                  ConfirmationDialog().show(
                    context: context,
                    title: 'Discard Post?',
                    detailText: 'Do you want to discard your post?',
                    leftButtonText: 'Cancel',
                    rightButtonText: 'Discard',
                    onConfirm: () {
                      Navigator.of(context).pop();
                    },
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              Provider.of<AmityUIConfiguration>(context, listen: false)
                  .widgetBuilders
                  .buildCustomPostButton(
                    vm,
                    hasContent
                        ? () async {
                            if (vm.isUploadComplete) {
                              if (widget.community == null) {
                                //creat post in user Timeline
                                await vm.createPost(context,
                                    callback: (isSuccess, error) {
                                  if (isSuccess) {
                                    Navigator.of(context).pop();
                                    if (widget.isFromPostToPage) {
                                      Navigator.of(context).pop();
                                    }
                                  } else {}
                                });
                              } else {
                                //create post in Community
                                await vm.createPost(context,
                                    communityId: widget.community?.communityId!,
                                    callback: (isSuccess, error) async {
                                  if (isSuccess) {
                                    var roleVM =
                                        Provider.of<MemberManagementVM>(context,
                                            listen: false);
                                    roleVM.checkCurrentUserRole(
                                        widget.community!.communityId!);

                                    if (widget
                                        .community!.isPostReviewEnabled!) {
                                      if (!widget.community!.hasPermission(
                                          AmityPermission
                                              .REVIEW_COMMUNITY_POST)) {
                                        await AmityDialog().showAlertErrorDialog(
                                            title: "Post submitted",
                                            message:
                                                "Your post has been submitted to the pending list. It will be reviewed by community moderator");
                                      }
                                    }
                                    Navigator.of(context).pop();
                                    if (widget.isFromPostToPage) {
                                      Navigator.of(context).pop();
                                    }
                                    if (widget
                                        .community!.isPostReviewEnabled!) {
                                      Provider.of<CommuFeedVM>(context,
                                              listen: false)
                                          .initAmityPendingCommunityFeed(
                                              widget.community!.communityId!,
                                              AmityFeedType.REVIEWING);
                                    }

                                    // Navigator.of(context).push(MaterialPageRoute(
                                    //     builder: (context) => ChangeNotifierProvider(
                                    //           create: (context) => CommuFeedVM(),
                                    //           child: CommunityScreen(
                                    //             isFromFeed: true,
                                    //             community: widget.community!,
                                    //           ),
                                    //         )));
                                  }
                                });
                              }
                            }
                          }
                        : null,
                  ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Provider.of<AmityUIConfiguration>(context, listen: false)
                    .widgetBuilders
                    .buildPostAsButton(
                      AmityCoreClient.getCurrentUser(),
                      widget.community,
                      vm,
                      tappablePostAsButton,
                    ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Semantics(
                            identifier: 'create_post_v2',
                            child: TextField(
                              style: TextStyle(
                                  color:
                                      Provider.of<AmityUIConfiguration>(context)
                                          .appColors
                                          .base),
                              onChanged: (value) => vm.updatePostValidity(),
                              controller: vm.textEditingController,
                              scrollPhysics: const NeverScrollableScrollPhysics(),
                              maxLines: null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write something to post",
                                hintStyle: TextStyle(
                                    color:
                                        Provider.of<AmityUIConfiguration>(context)
                                            .appColors
                                            .userProfileTextColor),
                              ),
                              // style: t/1heme.textTheme.bodyText1.copyWith(color: Colors.grey),
                            ),
                          ),
                          Consumer<CreatePostVMV2>(
                            builder: (context, vm, _) =>
                                PostMedia(files: vm.files),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Semantics(
                        identifier: 'amityCameraPostButton',
                        child: _iconButton(
                          Icons.camera_alt_outlined,
                          isEnable: vm
                              .availableFileSelectionOptions()[MyFileType.image]!,
                          label: "Photo",
                          // debugingText:
                          //     "${vm2.isNotSelectVideoYet()}&& ${vm2.isNotSelectedFileYet()}",
                          onTap: () {
                            _handleCameraTap(context);
                          },
                        ),
                      ),
                      Semantics(
                        identifier: 'amityImagePostButton',
                        child: _iconButton(
                          Icons.image_outlined,
                          label: "Image",
                          isEnable: vm
                              .availableFileSelectionOptions()[MyFileType.image]!,
                          onTap: () async {
                            _handleImageTap(context);
                          },
                        ),
                      ),
                      Semantics(
                        identifier: 'amityVideoPostButton',
                        child: _iconButton(
                          Icons.play_circle_outline,
                          label: "Video",
                          isEnable: vm
                              .availableFileSelectionOptions()[MyFileType.video]!,
                          onTap: () async {
                            _handleVideoTap(context);
                          },
                        ),
                      ),
                      Semantics(
                        identifier: 'amityFilePostButton',
                        child: _iconButton(
                          Icons.attach_file_outlined,
                          label: "File",
                          isEnable: vm
                              .availableFileSelectionOptions()[MyFileType.file]!,
                          onTap: () async {
                            _handleFileTap(context);
                          },
                        ),
                      ),
                      Semantics(
                        identifier: 'amityMorePostButton',
                        child: _iconButton(
                          Icons.more_horiz,
                          isEnable: true,
                          label: "More",
                          onTap: () {
                            // TODO: Implement more options logic
                            _showMoreOptions(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _iconButton(IconData icon,
      {required String label,
      required VoidCallback onTap,
      required bool isEnable,
      String? debugingText}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        debugingText == null ? const SizedBox() : Text(debugingText),
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[200],
          child: IconButton(
            icon: Icon(
              icon,
              size: 18,
              color: isEnable ? Colors.black : Colors.grey,
            ),
            onPressed: () {
              if (isEnable) {
                onTap();
              }
            },
          ),
        ),
        // SizedBox(height: 4),
        // Text(label),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Consumer<CreatePostVMV2>(builder: (consumerContext, vm, _) {
          return ThemeConfig(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0), // Space at the top
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: _iconButton(Icons.camera_alt_outlined,
                            isEnable: vm.availableFileSelectionOptions()[
                                MyFileType.image]!,
                            label: "Camera",
                            onTap: () {}),
                        title: Text(
                          'Camera',
                          style: TextStyle(
                              color: vm.availableFileSelectionOptions()[
                                      MyFileType.image]!
                                  ? Colors.black
                                  : Colors.grey),
                        ),
                        onTap: () {
                          if (vm.availableFileSelectionOptions()[
                              MyFileType.image]!) {
                            _handleImageTap(context);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      ListTile(
                        leading: _iconButton(Icons.image_outlined,
                            isEnable: vm.availableFileSelectionOptions()[
                                MyFileType.image]!,
                            label: "Photo",
                            onTap: () {}),
                        title: Text(
                          'Photo',
                          style: TextStyle(
                              color: vm.availableFileSelectionOptions()[
                                      MyFileType.image]!
                                  ? Colors.black
                                  : Colors.grey),
                        ),
                        onTap: () {
                          if (vm.availableFileSelectionOptions()[
                              MyFileType.image]!) {
                            _handleImageTap(context);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      ListTile(
                        leading: _iconButton(Icons.attach_file_rounded,
                            isEnable: vm.availableFileSelectionOptions()[
                                MyFileType.file]!,
                            label: "Attachment",
                            onTap: () {}),
                        title: Text(
                          'Attachment',
                          style: TextStyle(
                              color: vm.availableFileSelectionOptions()[
                                      MyFileType.file]!
                                  ? Colors.black
                                  : Colors.grey),
                        ),
                        onTap: () {
                          if (vm.availableFileSelectionOptions()[
                              MyFileType.file]!) {
                            _handleFileTap(context);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      ListTile(
                        leading: _iconButton(
                          Icons.play_circle_outline_outlined,
                          isEnable: vm.availableFileSelectionOptions()[
                              MyFileType.video]!,
                          label: "Video",
                          onTap: () {},
                        ),
                        title: Text(
                          'Video',
                          style: TextStyle(
                              color: vm.availableFileSelectionOptions()[
                                      MyFileType.video]!
                                  ? Colors.black
                                  : Colors.grey),
                        ),
                        onTap: () {
                          if (vm.availableFileSelectionOptions()[
                              MyFileType.video]!) {
                            _handleVideoTap(context);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Post?'),
        content: const Text('Do you want to discard your post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCameraTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.cameraImage);
  }

  Future<void> _handleImageTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.galleryImage);
  }

  Future<void> _handleVideoTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.galleryVideo);
  }

  Future<void> _handleFileTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.filePicker);
  }

  Future<void> _pickMedia(BuildContext context, PickerAction action) async {
    var createPostVM = Provider.of<CreatePostVMV2>(context, listen: false);
    await createPostVM.pickFile(action);
  }
}
