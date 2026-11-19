import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/plugin/bridge/plugin_config_bridge.dart';
import 'package:zephyr/plugin/builtin_plugin_service.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';

/// 登录页的表单模式：插件读配置项 `auth.mode` 决定展示登录还是注册。
const String kManwabaAuthModeLogin = 'login';
const String kManwabaAuthModeRegister = 'register';

/// 打开漫屋吧登录 / 注册页。
///
/// 先把 `auth.mode` 写进插件配置，再进登录页：
/// 登录入口固定用登录表单，注册入口固定用注册表单，
/// 不会因为上一次停在注册模式而串掉。
Future<void> openManwabaAuth(
  BuildContext context, {
  required String mode,
}) async {
  await savePluginConfigValue(kBuiltinManwabaUuid, 'auth.mode', mode);
  if (!context.mounted) {
    return;
  }
  await context.pushRoute(LoginRoute(from: kBuiltinManwabaUuid));
}

/// 「更多」页顶部的漫屋吧账号入口。
///
/// 进入前先向内置漫源要一次用户信息（`getUserInfoBundle`），
/// 已登录就直接把账号名显示在副标题里，未登录提示去登录 / 注册。
class ManwabaAccountTile extends StatefulWidget {
  const ManwabaAccountTile({super.key});

  @override
  State<ManwabaAccountTile> createState() => _ManwabaAccountTileState();
}

class _ManwabaAccountTileState extends State<ManwabaAccountTile>
    with WidgetsBindingObserver {
  bool _loading = true;
  String _accountName = '';
  String _avatarUrl = '';
  String _avatarPath = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从别处登录（比如插件设置页）后切回来能立刻看到新账号。
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    // 首次构建时 _loading 已经是 true，不必再 setState（initState 里调用）。
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final response = await callUnifiedComicPlugin(
        from: kBuiltinManwabaUuid,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = envelope.data;
      final avatar = asJsonMap(data['avatar']);
      if (!mounted) {
        return;
      }
      setState(() {
        _accountName = (data['title']?.toString() ?? '').trim();
        _avatarUrl = avatar['url']?.toString() ?? '';
        _avatarPath = avatar['path']?.toString() ?? '';
        _loading = false;
      });
    } catch (e) {
      logger.e(e);
      if (!mounted) {
        return;
      }
      setState(() {
        _accountName = '';
        _avatarUrl = '';
        _avatarPath = '';
        _loading = false;
      });
    }
  }

  String get _subtitle {
    if (_loading) {
      return '正在读取账号信息…';
    }
    final name = _accountName.trim();
    // 未登录时插件把 title 直接回成插件名，按未登录处理。
    if (name.isEmpty || name == '未登录' || name == '漫屋吧账号') {
      return '未登录，点击登录 / 注册';
    }
    if (name == '登录已失效') {
      return '登录已失效，点击重新登录';
    }
    return '已登录：$name';
  }

  Future<void> _openLogin() async {
    await openManwabaAuth(context, mode: kManwabaAuthModeLogin);
    if (!mounted) {
      return;
    }
    await _load();
  }

  Widget _buildLeading() {
    if (_avatarUrl.trim().isEmpty && _avatarPath.trim().isEmpty) {
      return const Icon(Icons.account_circle_outlined);
    }
    return ClipOval(
      child: CoverWidget(
        fileServer: _avatarUrl,
        path: _avatarPath,
        id: 'manwaba_more_avatar',
        pictureType: PictureType.user,
        from: kBuiltinManwabaUuid,
        width: 40,
        height: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(),
      title: const Text('漫屋吧账号'),
      subtitle: Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: _openLogin,
    );
  }
}
