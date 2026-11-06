import 'package:neuro_app/core/extensions/build_context_l10n.dart';
import 'package:neuro_app/core/resources/errors/failures.dart';
import 'package:neuro_app/core/resources/styles/font_styles_manager.dart';
import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/services/router/routes.dart';
import 'package:neuro_app/core/widgets/animations/staggered_item_wrapper_widget.dart';
import 'package:neuro_app/core/widgets/messages/dialogs/details_dialog.dart';
import 'package:neuro_app/core/widgets/ui/fields/mode_switcher_widget.dart';
import 'package:neuro_app/core/widgets/ui/fields/questions_categories_picker_widget.dart';
import 'package:neuro_app/core/widgets/ui/fields/questions_count_picker_widget.dart';
import 'package:neuro_app/core/widgets/ui/fields/switch_tile_widget.dart';
import 'package:neuro_app/core/widgets/ui/icons/close_icon_widget.dart';
import 'package:neuro_app/core/widgets/ui/icons/information_icon_widget.dart';
import 'package:neuro_app/core/widgets/ui/states/error_state_body_widget.dart';
import 'package:neuro_app/features/tests/domain/entities/question_category.dart';
import 'package:neuro_app/features/tests/domain/entities/test_mode.dart';
import 'package:neuro_app/features/tests/domain/entities/test_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/router/app_arguments.dart';
import '../../../core/widgets/ui/fields/bottom_buttons_widget.dart';
import '../../../core/resources/styles/spaces_resources.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/widgets/ui/icons/switch_theme_icon_widget.dart';
import '../blocs/test_mode_settings/test_mode_settings_bloc.dart';

class TestModeSettingsView extends StatelessWidget {
  const TestModeSettingsView({super.key, this.arguments});

  final TestModeSettingsArguments? arguments;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.testPropertiesTitle),
        centerTitle: true,
        leading: CloseIconWidget(),
        actions: [
          if (kDebugMode) SwitchThemeIconWidget(),
          BlocBuilder<TestModeSettingsBloc, TestModeSettingsState>(
            builder: (context, state) {
              if (state.status == TestModeSettingsStatus.loaded) {
                return InformationIconWidget(
                  onPressed: () {
                    if (state.testOptions.selectedMode == TestMode.testing) {
                      _showTestModeDetailsDialog(context);
                    } else {
                      _showExploreModeDetailsDialog(context);
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Center(
        child: BlocConsumer<TestModeSettingsBloc, TestModeSettingsState>(
          buildWhen: (previous, current) {
            if (current.status == TestModeSettingsStatus.fetchingQuestions) {
              return false;
            }
            return previous.status != current.status;
          },
          listener: (BuildContext context, TestModeSettingsState state) {
            if (state.status == TestModeSettingsStatus.saved) {
              context.pushReplacementNamed(
                Routes.quizzing.name,
                extra: QuizzingArguments(
                  questions: state.questions,
                  testMode: state.testOptions.selectedMode,
                  lessonIds: state.testOptions.selectedLessonsIds,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == TestModeSettingsStatus.noQuestions) {
              return ErrorStateBodyWidget(
                title: context.l10n.testPropertiesTitle,
                failure: state.failure ?? UnknownFailure(),
                onCancel: () {
                  context.pop();
                },
              );
            }
            if (state.status == TestModeSettingsStatus.loaded ||
                state.status == TestModeSettingsStatus.fetchingQuestions) {
              return _LoadedView(key: ValueKey(state.testOptions.selectedMode), state: state);
            }
            if (state.status == TestModeSettingsStatus.error) {
              return ErrorStateBodyWidget(
                title: context.l10n.testPropertiesTitle,
                failure: state.failure ?? UnknownFailure(),
                onRetry: () {
                  context.read<TestModeSettingsBloc>().add(
                    TestModeSettingsLoadEvent(
                      unitIds: state.testOptions.selectedUnitsIds,
                      lessonIds: state.testOptions.selectedLessonsIds,
                    ),
                  );
                },
                onCancel: () {
                  context.pop();
                },
              );
            }
            return const _LoadingView();
          },
        ),
      ),
    );
  }

  void _showTestModeDetailsDialog(BuildContext context) {
    showDetailsDialog(
      context: context,
      title: context.l10n.testMode,
      content: Column(
        children: [
          ///
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: context.l10n.testModeDetailsTitle,
                  style: TextStylesResources.dialogBody.copyWith(
                    height: 2.2,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeightResources.bold,
                  ),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: context.l10n.testModeDetailsContent,
                  style: TextStylesResources.dialogBody.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeightResources.medium,
                    fontSize: FontSizeResources.s12,
                  ),
                ),
                const TextSpan(text: '\n\n'),
                TextSpan(
                  text: context.l10n.testModeAdditionalFeaturesTitle,
                  style: TextStylesResources.dialogBody.copyWith(
                    height: 2.2,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeightResources.bold,
                  ),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: context.l10n.testModeAdditionalFeaturesContent,
                  style: TextStylesResources.dialogBody.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeightResources.medium,
                    fontSize: FontSizeResources.s12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExploreModeDetailsDialog(BuildContext context) {
    showDetailsDialog(
      context: context,
      title: context.l10n.exploreMode,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ///
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: context.l10n.exploreModeDetailsTitle,
                  style: TextStylesResources.dialogBody.copyWith(
                    height: 2.2,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeightResources.bold,
                  ),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: context.l10n.exploreModeDetailsContent,
                  style: TextStylesResources.dialogBody.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeightResources.medium,
                    fontSize: FontSizeResources.s12,
                  ),
                ),
                const TextSpan(text: '\n\n'),
                TextSpan(
                  text: context.l10n.exploreModeAdditionalFeaturesTitle,
                  style: TextStylesResources.dialogBody.copyWith(
                    height: 2.2,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeightResources.bold,
                  ),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: context.l10n.exploreModeAdditionalFeaturesContent,
                  style: TextStylesResources.dialogBody.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeightResources.medium,
                    fontSize: FontSizeResources.s12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({super.key, required this.state});

  final TestModeSettingsState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: Paddings.screenSidesPadding,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: Paddings.listViewPadding,
              child: Column(
                spacing: SpacesResources.s2,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Mode Switcher
                  StaggeredItemWrapperWidget(
                    position: 0,
                    child: ModeSwitcherWidget(
                      firstOption: SwitchOption(
                        value: TestMode.exploring,
                        label: context.l10n.exploreMode,
                        icon: Icons.explore,
                      ),
                      secondOption: SwitchOption(
                        value: TestMode.testing,
                        label: context.l10n.testMode,
                        icon: Icons.science,
                      ),
                      currentValue: state.testOptions.selectedMode,
                      onChanged: (mode) {
                        context.read<TestModeSettingsBloc>().add(
                          TestModeSettingsUpdateModeEvent(selectedMode: mode),
                        );
                      },
                    ),
                  ),

                  /// Question Categories Picker
                  BlocBuilder<TestModeSettingsBloc, TestModeSettingsState>(
                    buildWhen: (previous, current) {
                      if (current.status == TestModeSettingsStatus.fetchingQuestions) {
                        return false;
                      }
                      if (previous.testOptions.selectedMode != current.testOptions.selectedMode) {
                        return true;
                      }
                      return previous.testOptions.selectedCategories !=
                          current.testOptions.selectedCategories;
                    },
                    builder: (context, state) {
                      if (state.testOptions.selectedMode != TestMode.exploring) {
                        return const SizedBox.shrink();
                      }

                      return StaggeredItemWrapperWidget(
                        key: ValueKey(state.testOptions.selectedMode),
                        position: 1,
                        child: QuestionCategoriesPickerWidget<QuestionCategory>(
                          categories: state.testOptions.categories ?? [],
                          selected: state.testOptions.selectedCategories ?? [],
                          onChanged: (value) {
                            context.read<TestModeSettingsBloc>().add(
                              TestModeSettingsUpdateCategoriesEvent(categories: value),
                            );
                          },
                          label: (category) => "${category.title} (${category.questionsCount})",
                        ),
                      );
                    },
                  ),

                  /// Question Count Picker
                  BlocBuilder<TestModeSettingsBloc, TestModeSettingsState>(
                    buildWhen: (previous, current) {
                      if (current.status == TestModeSettingsStatus.fetchingQuestions) {
                        return false;
                      }
                      if (previous.testOptions.selectedMode != current.testOptions.selectedMode) {
                        return true;
                      }
                      final cond1 =
                          previous.testOptions.selectedQuestionsCount !=
                          current.testOptions.selectedQuestionsCount;
                      final cond2 =
                          previous.testOptions.selectedCategories !=
                          current.testOptions.selectedCategories;
                      return cond1 || cond2;
                    },
                    builder: (context, state) {
                      if (state.testOptions.selectedMode != TestMode.exploring) {
                        return const SizedBox.shrink();
                      }
                      if (state.testOptions.selectedCategories?.isEmpty ?? true) {
                        return const SizedBox.shrink();
                      }
                      return StaggeredItemWrapperWidget(
                        key: ValueKey(state.testOptions.selectedMode),
                        position: 2,
                        child: QuestionCountPickerWidget(
                          options: state.testOptions.countOptions(),
                          initialCount: state.testOptions.selectedQuestionsCount,
                          onChanged: (value) {
                            context.read<TestModeSettingsBloc>().add(
                              TestModeSettingsUpdateQuestionsCountEvent(questionsCount: value),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  ///Switchers
                  BlocBuilder<TestModeSettingsBloc, TestModeSettingsState>(
                    buildWhen: (previous, current) {
                      if (current.status == TestModeSettingsStatus.fetchingQuestions) {
                        return false;
                      }
                      if (previous.testOptions.selectedMode != current.testOptions.selectedMode) {
                        return true;
                      }
                      if (previous.testOptions.enableSounds != current.testOptions.enableSounds) {
                        return true;
                      }
                      if (previous.testOptions.showTrueAnswers !=
                          current.testOptions.showTrueAnswers) {
                        return true;
                      }
                      return false;
                    },
                    builder: (context, state) {
                      return StaggeredItemWrapperWidget(
                        key: ValueKey(state.testOptions.selectedMode),
                        position: 3,
                        child: Card(
                          margin: Margins.zero,
                          child: Column(
                            children: [
                              if (state.testOptions.selectedMode == TestMode.exploring)
                                SwitchTileWidget(
                                  title: context.l10n.showTrueAnswerTitle,
                                  subtitle: context.l10n.showTrueAnswerSubtitle,
                                  enabled: state.testOptions.showTrueAnswers,
                                  onChanged: (value) {
                                    context.read<TestModeSettingsBloc>().add(
                                      TestModeSettingsUpdateShowTrueAnswersEvent(
                                        showTrueAnswers: value,
                                      ),
                                    );
                                  },
                                ),
                              SwitchTileWidget(
                                title: context.l10n.enableSoundEffectsTitle,
                                subtitle: context.l10n.enableSoundEffectsSubtitle,
                                enabled: state.testOptions.enableSounds,
                                onChanged: (value) {
                                  context.read<TestModeSettingsBloc>().add(
                                    TestModeSettingsUpdateEnableSoundsEvent(enableSounds: value),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<TestModeSettingsBloc, TestModeSettingsState>(
                buildWhen: (previous, current) {
                  if (previous.testOptions.selectedMode != current.testOptions.selectedMode) {
                    return true;
                  }
                  if (previous.testOptions.selectedCategories !=
                      current.testOptions.selectedCategories) {
                    return true;
                  }
                  if (previous.status != current.status) {
                    return true;
                  }

                  return previous.testOptions.selectedQuestionsCount !=
                      current.testOptions.selectedQuestionsCount;
                },
                builder: (context, state) {
                  bool isEnabled = state.testOptions.selectedQuestionsCount != null;
                  if (state.testOptions.selectedMode == TestMode.testing) {
                    isEnabled = true;
                  } else if (state.testOptions.selectedCategories?.isEmpty ?? true) {
                    isEnabled = false;
                  }
                  return BottomButtonWidget(
                    isLoading: state.status == TestModeSettingsStatus.fetchingQuestions,
                    isEnabled: isEnabled,
                    onPressed: () {
                      context.read<TestModeSettingsBloc>().add(const TestModeSettingsSubmitEvent());
                      // Navigate to testing view after saving settings
                    },
                    text: context.l10n.buttonsStartTest,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: _LoadedView(
        state: TestModeSettingsState(
          testOptions: TestOptions(
            showTrueAnswers: false,
            enableSounds: false,
            categories: List.generate(5, (index) => QuestionCategory.mock()),
            selectedCategories: [],

            selectedQuestionsCount: 0,
            selectedMode: TestMode.exploring,
            selectedUnitsIds: List.generate(5, (index) => index),
            selectedLessonsIds: List.generate(5, (index) => index),
          ),
        ),
      ),
    );
  }
}
