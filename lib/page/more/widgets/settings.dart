import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/more/widgets/manwaba_account_tile.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManwabaAccountTile(),
        _buildSectionTitle(context, '漫屋吧账号', Icons.person_outline),
        ListTile(
          leading: const Icon(Icons.login_outlined),
          title: const Text('账号登录'),
          subtitle: const Text('登录已有的漫屋吧账号'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openManwabaAuth(context, mode: kManwabaAuthModeLogin),
        ),
        ListTile(
          leading: const Icon(Icons.person_add_alt_1_outlined),
          title: const Text('切换注册'),
          subtitle: const Text('打开注册表单，注册成功后自动登录'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openManwabaAuth(context, mode: kManwabaAuthModeRegister),
        ),
        _buildSectionTitle(context, t.more.common, Icons.widgets_outlined),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(t.more.downloadTasks),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(DownloadTaskRoute()),
        ),
        ListTile(
          leading: const Icon(Icons.sync_outlined),
          title: Text(t.more.sync),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(SyncSettingRoute()),
        ),
        BlocSelector<ComicFollowCubit, ComicFollowState, int>(
          selector: (state) => state.updateCount,
          builder: (context, updateCount) {
            return ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(t.more.comicFollow),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (updateCount > 0) _NewBadge(count: updateCount),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => context.pushRoute(ComicFollowRoute()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.explore_outlined),
          title: Text(t.navigation.discover),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(const DiscoverRoute()),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(t.settings.globalTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(GlobalSettingRoute()),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 本地化的 NEW 徽标：追更未读数达到 99 时显示 99+。
class _NewBadge extends StatelessWidget {
  const _NewBadge({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        (count ?? 0) >= 99 ? '99+' : t.more.newBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
