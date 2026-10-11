import 'package:neuro_app/core/injector/app_injection.dart';
import 'package:neuro_app/core/extensions/build_context_l10n.dart';
import 'package:neuro_app/core/resources/styles/sizes_resources.dart';
import 'package:neuro_app/core/resources/styles/spaces_resources.dart';
import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/resources/styles/assets_resources.dart';
import 'package:neuro_app/core/resources/styles/font_styles_manager.dart';
import 'package:neuro_app/core/services/router/index.dart';
import 'package:neuro_app/core/widgets/messages/dialogs/details_dialog.dart';
import 'package:neuro_app/core/widgets/ui/icons/switch_theme_icon_widget.dart';
import 'package:neuro_app/features/settings/domain/entities/app_settings.dart';
import 'package:neuro_app/features/settings/domain/entities/version.dart';
import 'package:neuro_app/presentation/auth/state/bloc/auth_bloc.dart';
import 'package:neuro_app/presentation/root/blocs/theme/app_theme_bloc.dart';
import 'package:neuro_app/presentation/settings/widgets/setting_tile_widget.dart';
import 'package:neuro_app/presentation/settings/widgets/settings_card_title_widget.dart';
import 'package:neuro_app/presentation/settings/widgets/user_information_card_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        actions: [if (kDebugMode) SwitchThemeIconWidget()],
      ),
      body: Padding(
        padding: Paddings.screenSidesPadding,
        child: SingleChildScrollView(
          padding: Paddings.listViewPadding,
          child: Column(
            children: [
              const UserInformationCardWidget(),

              SizedBox(height: SpacesResources.s6),

              // Account Section
              SettingsCardTitleWidget(title: context.l10n.settingsAccountTitle),

              // Account Section Card
              Card(
                margin: Margins.cardMargin,
                child: Column(
                  children: [
                    SettingTileWidget(
                      leadingIcon: Icon(
                        Icons.person_outline,
                        size: SizesResources.iconSettingsTileHeight,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      trailingIcon: Icons.chevron_right,
                      title: context.l10n.buttonsUpdateUserData,
                      onTap: () {
                        context.pushNamed(Routes.updateUserData.name);
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,

                      indent: SizesResources.iconSettingsTileHeight * 2.5,
                      endIndent: SpacesResources.s16,
                    ),
                    SettingTileWidget(
                      leadingIcon: Icon(
                        Icons.lock_outline,
                        size: SizesResources.iconSettingsTileHeight,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      trailingIcon: Icons.chevron_right,
                      title: context.l10n.settingsUpdateMyPassword,
                      onTap: () {
                        context.pushNamed(Routes.updatePassword.name);
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,

                      indent: SizesResources.iconSettingsTileHeight * 2.5,
                      endIndent: SpacesResources.s16,
                    ),
                    SettingTileWidget(
                      leadingIcon: Icon(
                        Icons.notifications_outlined,
                        size: SizesResources.iconSettingsTileHeight,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      trailingIcon: Icons.chevron_right,
                      title: context.l10n.settingsManageNotifications,
                      onTap: () {
                        context.pushNamed(Routes.notificationsTopics.name);
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: SpacesResources.s6),

              // Preferences Section
              SettingsCardTitleWidget(title: context.l10n.settingsPreferencesTitle),
              // Preferences Section Card
              Card(
                margin: Margins.cardMargin,
                child: BlocBuilder<AppThemeBloc, AppThemeState>(
                  builder: (context, state) {
                    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                    return SettingTileWidget(
                      leadingIcon: Image.asset(
                        isDarkMode
                            ? UIImagesResources.brightnessDarkUIIcon
                            : UIImagesResources.brightnessLightUIIcon,
                        width: SizesResources.iconSettingsTileHeight,
                        height: SizesResources.iconSettingsTileHeight,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title:
                          isDarkMode
                              ? context.l10n.settingsSwitchToLightTheme
                              : context.l10n.settingsSwitchToDarkTheme,
                      onTap: () {
                        final bloc = context.read<AppThemeBloc>();
                        bloc.add(
                          ChangeAppThemeEvent(
                            isDarkMode ? AppThemes.lightTheme : AppThemes.darkTheme,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: SpacesResources.s6),

              // Other Section
              // Sign Out Card
              Card(
                margin: Margins.cardMargin,
                child: SettingTileWidget(
                  leadingIcon: Icon(
                    Icons.logout_outlined,
                    size: SizesResources.iconSettingsTileHeight,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  // trailingIcon: Icons.chevron_right,
                  title: context.l10n.buttonsSignOut,
                  onTap: () {
                    sl<AuthBloc>().add(const AuthSignOutEvent());
                  },
                ),
              ),
              SizedBox(height: SpacesResources.s6),
              _SettingsVersionButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsVersionButton extends StatelessWidget {
  const _SettingsVersionButton();

  @override
  Widget build(BuildContext context) {
    final version = sl<AppSettings>().version;

    return InkWell(
      borderRadius: BorderRadius.circular(SpacesResources.s12),
      onTap: () {
        _showVersionDetailsDialog(context, version);
      },
      child: Padding(
        padding: const EdgeInsets.all(SpacesResources.s8),
        child: Text(
          '${version.currentVersion} (${version.buildNumber})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

void _showVersionDetailsDialog(BuildContext context, Version version) {
  showDetailsDialog(
    context: context,
    title: context.l10n.versionDetailsTitle,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: SpacesResources.s4),
        _VersionDetailRow(
          label: context.l10n.versionDetailsAppVersionLabel,
          value: version.appVersion,
        ),
        if (version.appVersion != version.minimumVersion) ...[
          _VersionDetailRow(
            label: context.l10n.versionDetailsMinimumVersionLabel,
            value: version.minimumVersion,
          ),
        ],
        _VersionDetailRow(
          label: context.l10n.versionDetailsCurrentVersionLabel,
          value: version.currentVersion,
        ),
        _VersionDetailRow(
          label: context.l10n.versionDetailsBuildNumberLabel,
          value: version.buildNumber,
        ),
        if (version.patchNumber != null)
          _VersionDetailRow(
            label: context.l10n.versionDetailsPatchNumberLabel,
            value: version.patchNumber?.toString() ?? context.l10n.versionDetailsNotAvailableLabel,
          ),
        _VersionDetailRow(
          label: context.l10n.versionDetailsVersionStringLabel,
          value: version.versionString,
        ),
        SizedBox(height: SpacesResources.s2),
      ],
    ),
  );
}

class _VersionDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _VersionDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStylesResources.dialogBody.copyWith(
              height: 2.2,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeightResources.bold,
              fontSize: FontSizeResources.s10,
            ),
          ),
        ),
        const SizedBox(width: SpacesResources.s8),
        Expanded(
          flex: 1,
          child: Text(
            value.isEmpty ? context.l10n.versionDetailsNotAvailableLabel : value,
            style: TextStylesResources.dialogBody.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeightResources.medium,
              fontSize: FontSizeResources.s10,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
