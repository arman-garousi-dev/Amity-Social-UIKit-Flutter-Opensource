import 'package:amity_uikit_beta_service/components/theme_config.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notification_all_tab.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return DefaultTabController(
      length: 1,
      child: ThemeConfig(
        child: Scaffold(
          appBar: TabBar(
            tabAlignment: TabAlignment.start,
            physics: const BouncingScrollPhysics(),
            isScrollable: true,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor:
                Provider.of<AmityUIConfiguration>(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: "all"),
              // Tab(text: S.of(context).likes),
              // Tab(text: S.of(context).comments),
              // Tab(text: S.of(context).repost),
            ],
          ),
          body: const TabBarView(
            physics: BouncingScrollPhysics(),
            children: [
              NotificationAllTabScreen(),
              // NotificationAllTabScreen(),
              // NotificationAllTabScreen(),
              // NotificationAllTabScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
