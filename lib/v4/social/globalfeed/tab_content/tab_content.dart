import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/social/explore/amity_explore_component.dart';
import 'package:amity_uikit_beta_service/v4/social/my_community/my_community_component.dart';
import 'package:amity_uikit_beta_service/v4/social/social_home_page/bloc/social_home_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/social_home_page/bloc/social_home_event.dart';
import 'package:amity_uikit_beta_service/v4/social/social_home_page/bloc/social_home_state.dart';
import 'package:amity_uikit_beta_service/v4/utils/config_provider_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabContent extends StatelessWidget {
  const TabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialHomeBloc, SocialHomeState>(
      builder: (context, state) {
        final tabIndex = state is TabState ? state.selectedIndex : 0;
        if (tabIndex == 0) {
          context.read<SocialHomeBloc>().add(TabSelectedEvent(0));
          return const NewsFeedComponentConfigProviderWidget(
              pageId: 'social_home_page');
        } else if (tabIndex == 1) {
          context.read<SocialHomeBloc>().add(TabSelectedEvent(1));
          return AmityExploreComponent(
              pageId: 'social_home_page');
        } else {
          context.read<SocialHomeBloc>().add(TabSelectedEvent(2));
          return AmityMyCommunitiesComponent(
            pageId: 'social_home_page',
          );
        }
      },
    );
  }
}

class ExploreComponent extends NewBaseComponent {
  ExploreComponent(
      {Key? key, required String pageId, required String componentId})
      : super(key: key, pageId: pageId, componentId: componentId);

  @override
  Widget buildComponent(BuildContext context) {
    return const Center(child: Text('Explore Content'));
  }
}
