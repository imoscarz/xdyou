// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/dialogs/experiment_password_dialog.dart';
import 'package:watermeter/page/setting/dialogs/schoolnet_password_dialog.dart';
import 'package:watermeter/page/setting/dialogs/sport_password_dialog.dart';
import 'package:watermeter/page/setting/sections/shared.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class SettingAccountSection extends StatelessWidget {
  const SettingAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.account_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          if (!preference.getBool(preference.Preference.role)) ...[
            ListTile(
              title: Text(
                FlutterI18n.translate(
                  context,
                  "setting.sport_password_setting",
                ),
              ),
              trailing: const Icon(Icons.navigate_next),
              onTap: () {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => const SportPasswordDialog(),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text(
                FlutterI18n.translate(
                  context,
                  "setting.experiment_password_setting",
                ),
              ),
              trailing: const Icon(Icons.navigate_next),
              onTap: () {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => const ExperimentPasswordDialog(),
                );
              },
            ),
            const Divider(),
          ],
          ListTile(
            title: Text(
              FlutterI18n.translate(
                context,
                "setting.schoolnet_password_setting",
              ),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.schoolnet_password_description",
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const SchoolNetPasswordDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}
