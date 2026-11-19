import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_install_service.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

/// 内置漫源「漫屋吧」的 uuid。
const String kBuiltinManwabaUuid = 'c6aecd30-5e8f-40fb-8fe3-52881163bc59';

/// 曾经随包内置的「拷贝漫画 Copy4000」uuid。
///
/// 这一版起内置漫源换成漫屋吧，启动时把旧漫源从插件库里摘掉，
/// 避免升级后还残留一个默认的拷贝漫画源。
const String kLegacyCopy4000Uuid = '371d33c6-a901-434a-a0ae-d4ea80c7612f';

/// 内置漫源脚本在 asset 里的路径。
const String _kBuiltinManwabaAsset = 'asset/plugin/manwaba.cjs';

/// 首次启动时把内置漫源装进插件库，用户无需手动导入。
///
/// 必须在 `PluginRegistryService.init` 之后调用（安装流程会用注册表做去重）。
///
/// 只要本地已装脚本文本与随包脚本不一致（含旧版本、被删除过），
/// 就用随包脚本覆盖，保证升级 App 后拿到的就是这一版。
/// 任何失败都只记日志，绝不影响启动。
Future<void> ensureBuiltinPluginsInstalled() async {
  // 先摘掉旧的内置漫源，再装新的。
  await _removeLegacyBuiltinPlugin();

  try {
    final data = await rootBundle.load(_kBuiltinManwabaAsset);
    final script = utf8
        .decode(data.buffer.asUint8List(), allowMalformed: true)
        .trim();
    if (script.isEmpty) {
      logger.w('[builtin-plugin] 内置脚本为空，跳过');
      return;
    }

    final existing = _findInfoByUuid(kBuiltinManwabaUuid);
    if (existing != null &&
        !existing.isDeleted &&
        existing.originScript.trim() == script) {
      return;
    }

    await PluginInstallService.I.savePluginByScript(
      script,
      sourceLabel: '内置漫源',
      allowReplaceExisting: true,
      expectedUuid: kBuiltinManwabaUuid,
    );
    logger.d('[builtin-plugin] 已安装/更新内置漫源: $kBuiltinManwabaUuid');
  } catch (e, st) {
    logger.e(e, stackTrace: st);
  }
}

/// 把旧的内置漫源（拷贝漫画 Copy4000）标记为已删除并停用。
///
/// 只做软删除：脚本置空、移出漫源列表，不删该源已下载的漫画、
/// 收藏与历史记录，避免升级直接把用户数据清掉。
Future<void> _removeLegacyBuiltinPlugin() async {
  try {
    final existing = _findInfoByUuid(kLegacyCopy4000Uuid);
    if (existing == null || existing.isDeleted) {
      return;
    }

    final now = DateTime.now().toUtc();
    await PluginRegistryService.I.upsert(
      PluginInfo(
        id: existing.id,
        uuid: kLegacyCopy4000Uuid,
        version: existing.version,
        originScript: '',
        insertedAt: existing.insertedAt,
        updatedAt: now,
        isEnabled: false,
        isDeleted: true,
        deletedAt: now,
        sortOrder: existing.sortOrder,
        debug: existing.debug,
        debugUrl: existing.debugUrl,
        getInfoJson: existing.getInfoJson,
      ),
    );
    logger.d('[builtin-plugin] 已移除旧内置漫源: $kLegacyCopy4000Uuid');
  } catch (e, st) {
    logger.e(e, stackTrace: st);
  }
}

PluginInfo? _findInfoByUuid(String uuid) {
  final query = objectbox.pluginInfoBox
      .query(PluginInfo_.uuid.equals(uuid))
      .build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}
