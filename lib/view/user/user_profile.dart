import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/theme_config.dart';
import 'package:amity_uikit_beta_service/utils/dynamicSilverAppBar.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/create_post_screenV2.dart';
import 'package:amity_uikit_beta_service/view/social/user_follow_screen.dart';
import 'package:amity_uikit_beta_service/view/user/medie_component.dart';
import 'package:amity_uikit_beta_service/view/user/user_setting.dart';
import 'package:amity_uikit_beta_service/viewmodel/follower_following_viewmodel.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/custom_user_avatar.dart';
import '../../viewmodel/amity_viewmodel.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import '../../viewmodel/user_feed_viewmodel.dart';
import '../social/global_feed.dart';
import 'edit_profile.dart';

class UserProfileScreen extends StatefulWidget {
  final AmityUser? amityUser;
  final String amityUserId;
  bool? isEnableAppbar = true;
  Widget? customActions = Container();
  Widget? customProfile = Container();

  UserProfileScreen(
      {Key? key,
      this.amityUser,
      this.isEnableAppbar,
      this.customActions,
      this.customProfile,
      required this.amityUserId})
      : super(key: key);

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    if (widget.amityUser != null) {
      Provider.of<UserFeedVM>(context, listen: false).initUserFeed(
          amityUser: widget.amityUser, userId: widget.amityUser!.userId!);
    } else {
      Provider.of<UserFeedVM>(context, listen: false)
          .initUserFeed(userId: widget.amityUserId);
    }
  }

  String getFollowingStatusString(AmityFollowStatus amityFollowStatus) {
    if (amityFollowStatus == AmityFollowStatus.NONE) {
      return "Follow";
    } else if (amityFollowStatus == AmityFollowStatus.PENDING) {
      return "Pending";
    } else if (amityFollowStatus == AmityFollowStatus.ACCEPTED) {
      return "Following";
    } else if (amityFollowStatus == AmityFollowStatus.BLOCKED) {
      return "Blocked";
    } else {
      return "Miss Type";
    }
  }

  Color getFollowingStatusColor(AmityFollowStatus amityFollowStatus) {
    if (amityFollowStatus == AmityFollowStatus.NONE) {
      return Provider.of<AmityUIConfiguration>(context).primaryColor;
    } else if (amityFollowStatus == AmityFollowStatus.PENDING) {
      return Colors.grey;
    } else if (amityFollowStatus == AmityFollowStatus.ACCEPTED) {
      return Colors.white;
    } else {
      return Colors.white;
    }
  }

  Color getFollowingStatusTextColor(AmityFollowStatus amityFollowStatus) {
    if (amityFollowStatus == AmityFollowStatus.NONE) {
      return Colors.white;
    } else if (amityFollowStatus == AmityFollowStatus.PENDING) {
      return Colors.white;
    } else if (amityFollowStatus == AmityFollowStatus.ACCEPTED) {
      return Provider.of<AmityUIConfiguration>(context).primaryColor;
    } else {
      return Colors.red;
    }
  }

  AmityUser getAmityUser() {
    if (Provider.of<UserFeedVM>(context).amityUser!.userId ==
        AmityCoreClient.getCurrentUser().userId) {
      return Provider.of<AmityVM>(context).currentamityUser!;
    } else {
      return Provider.of<UserFeedVM>(context).amityUser!;
    }
  }

  @override
  Widget build(BuildContext context) {
    var isCurrentUser =
        AmityCoreClient.getCurrentUser().userId == widget.amityUserId;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final myAppBar = AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        color: Provider.of<AmityUIConfiguration>(context).primaryColor,
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: Icon(
          Icons.chevron_left,
          color: Provider.of<AmityUIConfiguration>(context).appColors.base,
          size: 24,
        ),
      ),
      elevation: 0,
    );
    final bheight = mediaQuery.size.height -
        mediaQuery.padding.top -
        myAppBar.preferredSize.height;

    return Consumer<UserFeedVM>(builder: (context, vm, _) {
      if (vm.amityUser != null) {
        Widget buildPrivateAccountWidget(double bheight) {
          return SingleChildScrollView(
            child: Container(
              color: Provider.of<AmityUIConfiguration>(context)
                  .appColors
                  .baseShade4,
              width: MediaQuery.of(context).size.width,
              height: bheight - 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/privateIcon.png",
                    package: "amity_uikit_beta_service",
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "This account is private",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff292B32)),
                  ),
                  const Text(
                    "Follow this user to see all posts",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffA5A9B5)),
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildNoPostsWidget(double bheight, BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              color: Provider.of<AmityUIConfiguration>(context)
                  .appColors
                  .baseShade4,
              width: MediaQuery.of(context).size.width,
              height: bheight - 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/noPostYet.png",
                    package: "amity_uikit_beta_service",
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No post yet",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xffA5A9B5)),
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildContent(BuildContext context, double bheight) {
          if (vm.amityMyFollowInfo.status != AmityFollowStatus.ACCEPTED &&
              vm.amityUser!.userId != AmityCoreClient.getUserId()) {
            return buildPrivateAccountWidget(bheight);
          } else if (vm.amityPosts.isEmpty) {
            return buildNoPostsWidget(bheight, context);
          } else {
            return Container(
              color: Provider.of<AmityUIConfiguration>(context)
                  .appColors
                  .baseShade4,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: Provider.of<UserFeedVM>(context).amityPosts.length,
                itemBuilder: (context, index) {
                  return StreamBuilder<AmityPost>(
                    stream: vm.amityPosts[index].listen.stream,
                    initialData: vm.amityPosts[index],
                    builder: (context, snapshot) {
                      return PostWidget(
                        isPostDetail: false,
                        feedType: FeedType.user,
                        showCommunity: false,
                        showlatestComment: true,
                        isFromFeed: true,
                        post: snapshot.data!,
                        theme: theme,
                        postIndex: index,
                      );
                    },
                  );
                },
              ),
            );
          }
        }

        var tablist = [
          RefreshIndicator(
              color: Provider.of<AmityUIConfiguration>(context).primaryColor,
              onRefresh: () async {
                if (widget.amityUser != null) {
                  await Provider.of<UserFeedVM>(context, listen: false)
                      .initUserFeed(
                          amityUser: widget.amityUser,
                          userId: widget.amityUser!.userId!);
                } else {
                  await Provider.of<UserFeedVM>(context, listen: false)
                      .initUserFeed(userId: widget.amityUserId);
                }
              },
              child: buildContent(context, bheight)),
          MediaGalleryPage(
            galleryFeed: GalleryFeed.user,
            onRefresh: () async {
              if (widget.amityUser != null) {
                await Provider.of<UserFeedVM>(context, listen: false)
                    .initUserFeed(
                        amityUser: widget.amityUser,
                        userId: widget.amityUser!.userId!);
              } else {
                await Provider.of<UserFeedVM>(context, listen: false)
                    .initUserFeed(userId: widget.amityUserId);
              }
            },
          )
        ];
        return ThemeConfig(
          child: Scaffold(
            // appBar: AppBar(
            //   elevation: 0,
            //   backgroundColor: Colors.white,
            //   leading: IconButton(
            //     icon: Icon(Icons.chevron_left, color: Colors.black),
            //     onPressed: () => Navigator.of(context).pop(),
            //   ),
            // ),
            floatingActionButton:
                widget.amityUserId != AmityCoreClient.getCurrentUser().userId
                    ? null
                    : FloatingActionButton(
                        shape: const CircleBorder(),
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AmityCreatePostV2Screen(
                              amityUser: widget.amityUser,
                            ),
                          ));
                          Provider.of<UserFeedVM>(context, listen: false)
                              .initUserFeed(userId: widget.amityUserId);
                        },
                        backgroundColor: AmityUIConfiguration().primaryColor,
                        child: Provider.of<AmityUIConfiguration>(context)
                            .iconConfig
                            .postIcon(iconSize: 28, color: Colors.white),
                      ),
            backgroundColor:
                Provider.of<AmityUIConfiguration>(context).appColors.baseShade4,
            body: DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  var followWidget = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Container(
                      //     width: constraints.maxWidth * 0.35,
                      //     decoration: BoxDecoration(
                      //         border: Border.all(
                      //             color: Provider.of<
                      //                         AmityUIConfiguration>(
                      //                     context)
                      //                 .primaryColor,
                      //             style: BorderStyle.solid,
                      //             width: 1),
                      //         borderRadius:
                      //             BorderRadius.circular(10),
                      //         color: Colors.white),
                      //     padding: const EdgeInsets.fromLTRB(
                      //         10, 10, 10, 10),
                      //     child: Text(
                      //       "Messages",
                      //       style: theme.textTheme.subtitle2!
                      //           .copyWith(
                      //         color: Provider.of<
                      //                     AmityUIConfiguration>(
                      //                 context)
                      //             .primaryColor,
                      //         fontSize: 12,
                      //       ),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //   ),
                      // ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(),
                          child: vm.amityMyFollowInfo.id == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            Provider.of<AmityUIConfiguration>(
                                                    context)
                                                .primaryColor,
                                        style: BorderStyle.solid,
                                        width: 1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: Text(
                                    "",
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall!.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : StreamBuilder<AmityUserFollowInfo>(
                                  stream: vm.amityMyFollowInfo.listen.stream,
                                  initialData: vm.amityMyFollowInfo,
                                  builder: (context, snapshot) {
                                    return FadeAnimation(
                                        child: snapshot.data!.status ==
                                                AmityFollowStatus.ACCEPTED
                                            ? const SizedBox()
                                            : GestureDetector(
                                                onTap: () {
                                                  vm.followButtonAction(
                                                      vm.amityUser!,
                                                      snapshot.data!.status);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              getFollowingStatusTextColor(
                                                                  snapshot.data!
                                                                      .status),
                                                          style:
                                                              BorderStyle.solid,
                                                          width: 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      color:
                                                          getFollowingStatusColor(
                                                              snapshot.data!
                                                                  .status)),
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 10, 10, 10),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.add,
                                                        size: 16,
                                                        color: Provider.of<
                                                                    AmityUIConfiguration>(
                                                                context)
                                                            .appColors
                                                            .userProfileBGColor,
                                                        weight: 4,
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        getFollowingStatusString(
                                                            snapshot
                                                                .data!.status),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: theme.textTheme
                                                            .titleSmall!
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              getFollowingStatusTextColor(
                                                                  snapshot.data!
                                                                      .status),
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ));
                                  }),
                        ),
                      ),
                    ],
                  );
                  return <Widget>[
                    DynamicSliverAppBar(
                      shadowColor: Colors.white,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor:
                          Provider.of<AmityUIConfiguration>(context)
                              .appColors
                              .baseBackground,
                      floating: false,
                      pinned: true,
                      leading: AmityCoreClient.getCurrentUser().userId ==
                                  Provider.of<UserFeedVM>(context)
                                      .amityUser!
                                      .userId &&
                              widget.customActions != null
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color:
                                    Provider.of<AmityUIConfiguration>(context)
                                        .appColors
                                        .base,
                                size: 30,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                      flexibleSpace: Column(
                        children: [
                          const SizedBox(height: 120),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 64,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      widget.customProfile != null
                                          ? widget.customProfile!
                                          : FadedScaleAnimation(
                                              child: getAvatarImage(
                                                  isCurrentUser
                                                      ? Provider.of<AmityVM>(
                                                          context,
                                                        )
                                                          .currentamityUser
                                                          ?.avatarUrl
                                                      : Provider.of<UserFeedVM>(
                                                              context)
                                                          .amityUser!
                                                          .avatarUrl,
                                                  radius: 32)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            // Text(vm.amityMyFollowInfo.status
                                            //     .toString()),
                                            Text(
                                              getAmityUser().displayName ??
                                                  "",
                                              style: TextStyle(
                                                color: Provider.of<
                                                            AmityUIConfiguration>(
                                                        context)
                                                    .appColors
                                                    .base,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                            vm.amityMyFollowInfo.id == null
                                                ? const SizedBox()
                                                : StreamBuilder<
                                                        AmityUserFollowInfo>(
                                                    stream: vm
                                                        .amityMyFollowInfo
                                                        .listen
                                                        .stream,
                                                    initialData:
                                                        vm.amityMyFollowInfo,
                                                    builder:
                                                        (context, snapshot) {
                                                      return Row(
                                                        children: [
                                                          // Text('${  vm.amityMyFollowInfo.followerCount
                                                          //     .toString()} Posts  '),
                                                          GestureDetector(
                                                            onTap: () {
                                                              Navigator.of(context).push(MaterialPageRoute(
                                                                  builder: (context) => ChangeNotifierProvider(
                                                                      create: (context) =>
                                                                          FollowerVM(),
                                                                      child: FollowScreen(
                                                                          followScreenType: FollowScreenType
                                                                              .following,
                                                                          key:
                                                                              UniqueKey(),
                                                                          userId:
                                                                              widget.amityUserId,
                                                                          displayName: getAmityUser().displayName))));
                                                            },
                                                            child: Text(
                                                                '${snapshot.data!.followingCount} following  ',
                                                                style: TextStyle(
                                                                    color: Provider.of<AmityUIConfiguration>(
                                                                            context)
                                                                        .appColors
                                                                        .base)),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              Navigator.of(context).push(MaterialPageRoute(
                                                                  builder: (context) => ChangeNotifierProvider(
                                                                      create: (context) =>
                                                                          FollowerVM(),
                                                                      child: FollowScreen(
                                                                          followScreenType: FollowScreenType
                                                                              .follower,
                                                                          key:
                                                                              UniqueKey(),
                                                                          userId:
                                                                              widget.amityUserId,
                                                                          displayName: getAmityUser().displayName))));
                                                            },
                                                            child: Text(
                                                              '${snapshot.data!.followerCount} followers',
                                                              style: TextStyle(
                                                                  color: Provider.of<AmityUIConfiguration>(
                                                                          context)
                                                                      .appColors
                                                                      .base),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    })
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    children: [
                                      Text(
                                        getAmityUser().description ?? "",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Provider.of<
                                                        AmityUIConfiguration>(
                                                    context)
                                                .appColors
                                                .base),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AmityCoreClient.getCurrentUser().userId ==
                                        Provider.of<UserFeedVM>(context)
                                            .amityUser!
                                            .userId
                                    ? widget.customActions ??
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  await Navigator.of(context)
                                                      .push(MaterialPageRoute(
                                                          builder: (context) =>
                                                              ProfileScreen(
                                                                  user: vm
                                                                      .amityUser!)));
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xffA5A9B5),
                                                        style:
                                                            BorderStyle.solid,
                                                        width: 1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: Provider.of<
                                                                AmityUIConfiguration>(
                                                            context)
                                                        .appColors
                                                        .baseBackground,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 10, 10, 10),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        color: Provider.of<
                                                                    AmityUIConfiguration>(
                                                                context)
                                                            .appColors
                                                            .base,
                                                      ),
                                                      Text(
                                                        "Edit Profile",
                                                        style: theme.textTheme
                                                            .titleSmall!
                                                            .copyWith(
                                                          color: Provider.of<
                                                                      AmityUIConfiguration>(
                                                                  context)
                                                              .appColors
                                                              .base,
                                                          fontSize: 15,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                    : followWidget,
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      actions: [
                        vm.amityMyFollowInfo.id == null
                            ? const SizedBox()
                            : StreamBuilder<AmityUserFollowInfo>(
                                stream: vm.amityMyFollowInfo.listen.stream,
                                initialData: vm.amityMyFollowInfo,
                                builder: (context, snapshot) {
                                  return AmityCoreClient.getCurrentUser()
                                                  .userId ==
                                              Provider.of<UserFeedVM>(context)
                                                  .amityUser!
                                                  .userId &&
                                          widget.customActions != null
                                      ? Container()
                                      : IconButton(
                                          icon: Icon(Icons.more_horiz,
                                              color: Provider.of<
                                                          AmityUIConfiguration>(
                                                      context)
                                                  .appColors
                                                  .base),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserSettingPage(
                                                          amityMyFollowInfo:
                                                              snapshot.data!,
                                                          amityUser:
                                                              vm.amityUser!,
                                                        )));
                                          },
                                        );
                                }),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color:
                                    Provider.of<AmityUIConfiguration>(context)
                                        .appColors
                                        .baseBackground,
                                child: TabBar(
                                  dividerColor:
                                      Provider.of<AmityUIConfiguration>(context)
                                          .appColors
                                          .baseBackground,
                                  tabAlignment: TabAlignment.start,
                                  controller: _tabController,
                                  isScrollable: true,
                                  labelColor:
                                      Provider.of<AmityUIConfiguration>(context)
                                          .appColors
                                          .primary,
                                  indicatorColor:
                                      Provider.of<AmityUIConfiguration>(context)
                                          .appColors
                                          .primary,
                                  labelStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                  tabs: const [
                                    Tab(text: "Timeline"),
                                    Tab(text: "Gallery"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(controller: _tabController, children: tablist),
              ),
            ),
          ),
        );
      } else {
        return ThemeConfig(
          child: Scaffold(
            backgroundColor: Provider.of<AmityUIConfiguration>(context)
                .appColors
                .baseBackground,
          ),
        );
      }
    });
  }
}

// TabBarView(
//               controller: _tabController,
//               children: tablist,
//             ),
