import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/theme_config.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/custom_user_avatar.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import '../../viewmodel/user_viewmodel.dart';
import 'create_group_chat_screen.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});
  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // community = widget.community;

    Future.delayed(Duration.zero, () {
      Provider.of<UserVM>(context, listen: false).clearSelectedUser();
      Provider.of<UserVM>(context, listen: false).getUsers();
    });
  }

  int getLength() {
    if (Provider.of<UserVM>(context, listen: false).getUserList().isEmpty) {
      return 0;
    }
    int length =
        Provider.of<UserVM>(context, listen: false).getUserList().length;
    return length;
  }

  int getSelectedLength() {
    if (Provider.of<UserVM>(context, listen: false).selectedUserList.isEmpty) {
      return 0;
    }
    int length =
        Provider.of<UserVM>(context, listen: false).selectedUserList.length;

    return length;
  }

  void onNextTap() async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => CreateChatGroup(
        key: UniqueKey(),
        userIds: Provider.of<UserVM>(context, listen: false).selectedUserList,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        AppBar().preferredSize.height;

    final theme = Theme.of(context);
    return Consumer<UserVM>(builder: (context, vm, _) {
      return ThemeConfig(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Select Users",
                style: TextStyle(color: Colors.black)),
            leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child:
                  const Icon(Icons.chevron_left, color: Colors.black, size: 35),
            ),
            actions: [
              getSelectedLength() > 0
                  ? TextButton(
                      onPressed: () {
                        onNextTap();
                      },
                      child: const Text("Next"))
                  : Container()
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    height: bHeight,

                    // color: ApplicationColors.lightGrey,
                    child: FadedSlideAnimation(
                      beginOffset: const Offset(0, 0.3),
                      endOffset: const Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: Column(
                        children: [
                          getLength() < 1
                              ? Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color:
                                            Provider.of<AmityUIConfiguration>(
                                                    context)
                                                .primaryColor),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    // shrinkWrap: true,
                                    itemCount: getLength(),
                                    itemBuilder: (context, index) {
                                      return UserWidget(
                                        theme: theme,
                                        index: index,
                                        user: Provider.of<UserVM>(context,
                                                listen: false)
                                            .getUserList()[index],
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class UserWidget extends StatelessWidget {
  const UserWidget(
      {Key? key, required this.user, required this.theme, required this.index})
      : super(key: key);

  final ThemeData theme;
  final AmityUser user;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(0),
              onTap: () {
                Provider.of<UserVM>(context, listen: false).setSelectedUserList(
                    Provider.of<UserVM>(context, listen: false)
                        .getUserList()[index]
                        .userId!);
              },
              leading: FadeAnimation(child: getAvatarImage(user.avatarUrl!)),
              title: Text(
                user.displayName ?? "",
                style: Provider.of<AmityUIConfiguration>(context)
                    .titleTextStyle
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              trailing: Provider.of<UserVM>(context, listen: true)
                      .checkIfSelected(
                          Provider.of<UserVM>(context, listen: false)
                              .getUserList()[index]
                              .userId!)
                  ? Icon(
                      Icons.check_rounded,
                      color: Provider.of<AmityUIConfiguration>(context)
                          .primaryColor,
                    )
                  : null,
            ),
            const Divider(
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}
