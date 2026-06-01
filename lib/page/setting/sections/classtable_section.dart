// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/controller/classtable_controller.dart';
import 'package:watermeter/controller/exam_controller.dart';
import 'package:watermeter/controller/other_experiment_controller.dart';
import 'package:watermeter/controller/physics_experiment_controller.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/setting/dialogs/change_swift_dialog.dart';
import 'package:watermeter/page/setting/dialogs/semester_switch_dialog.dart';
import 'package:watermeter/page/setting/sections/cancel_button.dart';
import 'package:watermeter/page/setting/sections/shared.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/pick_file.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/system_calendar_sync_service.dart';
import 'package:watermeter/repository/user_defined_class_file.dart';

class SettingClassTableSection extends StatelessWidget {
  final VoidCallback onChanged;

  const SettingClassTableSection({super.key, required this.onChanged});

  bool get _isSemesterAwareControllerLoading =>
      ClassTableController.i.schoolClassTableStateSignal.value.isLoading ||
      ExamController.i.examInfoStateSignal.value.isLoading ||
      PhysicsExperimentController
          .i
          .physicsExperimentStateSignal
          .value
          .isLoading ||
      OtherExperimentController.i.otherExperimentStateSignal.value.isLoading;

  Future<void> _waitForSemesterAwareReloads() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stopwatch = Stopwatch()..start();
    while (_isSemesterAwareControllerLoading &&
        stopwatch.elapsed < const Duration(seconds: 30)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.classtable_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.background")),
            trailing: Switch(
              value: preference.getBool(preference.Preference.decorated),
              onChanged: (bool value) {
                if (value &&
                    !preference.getBool(preference.Preference.decoration)) {
                  showToast(
                    context: context,
                    msg: FlutterI18n.translate(
                      context,
                      "setting.no_background",
                    ),
                  );
                  return;
                }
                preference.setBool(preference.Preference.decorated, value);
                onChanged();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.choose_background"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _chooseBackground(context),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.clear_user_class"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _confirmClearUserClass(context),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.class_refresh"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _confirmRefreshClassData(context),
          ),
          const Divider(),
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.class_swift")),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.class_swift_description",
                translationParams: {
                  "swift": preference
                      .getInt(preference.Preference.swift)
                      .toString(),
                },
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => ChangeSwiftDialog(),
              ).then((value) => onChanged());
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.semester_change"),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.semester_change_description",
                translationParams: {
                  "semester": preference.getString(
                    preference.Preference.currentSemester,
                  ),
                },
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _changeSemester(context),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseBackground(BuildContext context) async {
    PlatformFile? result;
    try {
      result = await pickFile(type: FileType.image);
    } on MissingStoragePermissionException {
      if (context.mounted) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(context, "setting.no_permission"),
        );
      }
    }
    if (result != null) {
      File(
        result.path!,
      ).copySync("${supportPath.path}/${ClassTableController.decorationName}");
      preference.setBool(preference.Preference.decoration, true);
      if (context.mounted) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(context, "setting.successful_setting"),
        );
      }
      return;
    }
    if (context.mounted) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "setting.failure_setting"),
      );
    }
  }

  Future<void> _confirmClearUserClass(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.clear_user_class_title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.clear_user_class_content"),
        ),
        actions: [
          const SettingCancelButton(),
          TextButton(
            onPressed: () {
              UserDefinedClassFile.clearUserDefinedClass();
              ClassTableController.i.userDefinedClassSignal.value =
                  UserDefinedClassData.empty();
              onChanged();
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.clear_user_class_clear",
                ),
              );
              Navigator.pop(context);
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRefreshClassData(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.class_refresh_title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.class_refresh_content"),
        ),
        actions: [
          const SettingCancelButton(),
          TextButton(
            onPressed: () async {
              await Future.wait([
                ClassTableController.i.reloadClassTable(),
                ExamController.i.reloadExamInfo(),
                PhysicsExperimentController.i.reloadPhysicsExperiment(),
                OtherExperimentController.i.reloadOtherExperiment(),
              ]);
              await maybeAutoSyncSystemCalendar();
              onChanged();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSemester(BuildContext context) async {
    final changed = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => SemesterSwitchDialog(),
    );
    if (changed != true) return;
    onChanged();
    if (context.mounted) {
      showToast(context: context, msg: "Updating data");
    }
    await _waitForSemesterAwareReloads();
    await maybeAutoSyncSystemCalendar();
    onChanged();
  }
}
