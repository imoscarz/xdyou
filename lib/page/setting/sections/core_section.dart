// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get_it/get_it.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:watermeter/controller/classtable_controller.dart';
import 'package:watermeter/controller/theme_controller.dart';
import 'package:watermeter/external/ruisi_flutter/lib/controller/ruisi_controller.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/setting/notification_page/notification_debug_page.dart';
import 'package:watermeter/page/setting/sections/cancel_button.dart';
import 'package:watermeter/page/setting/sections/shared.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/physics_experiment_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/user_defined_class_file.dart';
import 'package:watermeter/repository/widget_state_sync.dart';
import 'package:watermeter/repository/xidian_ids/classtable_session.dart';
import 'package:watermeter/repository/xidian_ids/energy_session.dart';
import 'package:watermeter/repository/xidian_ids/exam_session.dart';
import 'package:watermeter/repository/xidian_ids/score_session.dart';
import 'package:watermeter/repository/xidian_ids/sysj_session.dart';
import 'package:watermeter/repository/xidian_sport_session.dart';

class SettingCoreSection extends StatelessWidget {
  const SettingCoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.core_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.check_logger")),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => context.push(TalkerScreen(talker: log)),
          ),
          const Divider(),
          if (Platform.isAndroid || Platform.isIOS) ...[
            ListTile(
              title: Text(
                FlutterI18n.translate(
                  context,
                  "setting.notification_debug_page",
                ),
              ),
              trailing: const Icon(Icons.navigate_next),
              onTap: () => context.push(NotificationDebugPage()),
            ),
            const Divider(),
          ],
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.clear_and_restart"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _confirmClearAndRestart(context),
          ),
          const Divider(),
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.logout")),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAndRestart(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(
            context,
            "setting.clear_and_restart_dialog.title",
          ),
        ),
        content: Text(
          FlutterI18n.translate(
            context,
            "setting.clear_and_restart_dialog.content",
          ),
        ),
        actions: [
          const SettingCancelButton(),
          TextButton(
            onPressed: () async {
              final pd = ProgressDialog(context: context);
              pd.show(
                msg: FlutterI18n.translate(
                  context,
                  "setting.clear_and_restart_dialog.cleaning",
                ),
              );

              try {
                await NetworkSession().clearCookieJar();
              } on Exception {
                // I don't care.
              }

              try {
                await SportSession().sportCookieJar.deleteAll();
              } on Exception {
                // I don't care.
              }

              EnergySession.clearCache();
              EnergySession.clearElectricityHistory();
              for (final value in [
                ClassTableSession.schoolClassName,
                ExamSession.examDataCacheName,
                ExperimentSession.physicsExperimentCacheName,
                SysjSession.otherExperimentCacheName,
                ScoreSession.scoreListCacheName,
              ]) {
                final file = File("${supportPath.path}/$value");
                if (file.existsSync()) {
                  file.deleteSync();
                }
              }

              if (!context.mounted) return;
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.clear_and_restart_dialog.clear",
                ),
              );
              _restartApp(
                context,
                iosTitleKey: "restart_app.title_cache_cleared",
              );
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.logout_dialog.title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.logout_dialog.content"),
        ),
        actions: [
          const SettingCancelButton(),
          TextButton(
            onPressed: () async {
              final pd = ProgressDialog(context: context);
              pd.show(
                msg: FlutterI18n.translate(
                  context,
                  "setting.logout_dialog.logging_out",
                ),
              );

              try {
                await NetworkSession().clearCookieJar();
              } on Exception {
                // I don't care.
              }

              try {
                await SportSession().sportCookieJar.deleteAll();
              } on Exception {
                // I don't care.
              }

              EnergySession.clearCache();
              EnergySession.clearElectricityHistory();
              for (final value in [
                ClassTableSession.schoolClassName,
                UserDefinedClassFile.userDefinedClassName,
                ClassTableController.decorationName,
                ExamSession.examDataCacheName,
                ExperimentSession.physicsExperimentCacheName,
                SysjSession.otherExperimentCacheName,
                ScoreSession.scoreListCacheName,
              ]) {
                final file = File("${supportPath.path}/$value");
                if (file.existsSync()) {
                  file.deleteSync();
                }
              }
              await GetIt.instance<RuisiService>().logout();
              await preference.prefrenceClear();
              ThemeController.i.updateTheme();
              await syncWidgetLoginState(false);
              await clearWidgetFiles();

              if (!context.mounted) return;
              pd.close();
              _restartApp(context, iosTitleKey: "restart_app.title_logged_out");
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  void _restartApp(BuildContext context, {required String iosTitleKey}) {
    if (Platform.isIOS) {
      Restart.restartApp(
        mode: RestartMode.notificationFallback,
        notificationTitle: FlutterI18n.translate(context, iosTitleKey),
        notificationBody: FlutterI18n.translate(context, "restart_app.content"),
      );
    } else {
      Restart.restartApp();
    }
  }
}
