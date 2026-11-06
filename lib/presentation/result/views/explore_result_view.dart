import 'package:neuro_app/core/extensions/build_context_l10n.dart';
import 'package:neuro_app/core/resources/styles/assets_resources.dart';
import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/resources/styles/spaces_resources.dart';
import 'package:neuro_app/core/resources/themes/extensions/extra_colors.dart';
import 'package:neuro_app/core/services/router/app_arguments.dart';
import 'package:neuro_app/core/services/router/routes.dart';
import 'package:neuro_app/core/widgets/animations/staggered_item_wrapper_widget.dart';
import 'package:neuro_app/core/widgets/messages/sheets/app_bottom_sheet.dart';
import 'package:neuro_app/core/widgets/ui/icons/close_icon_widget.dart';
import 'package:neuro_app/core/widgets/ui/icons/retry_icon_widget.dart';
import 'package:neuro_app/core/widgets/ui/states/error_state_body_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:neuro_app/features/results/domain/entities/result.dart';
import 'package:neuro_app/presentation/result/bloc/submit_results/explore_result_bloc.dart';
import 'package:neuro_app/presentation/result/widgets/previous_results_list_card_widget.dart';
import 'package:neuro_app/presentation/result/widgets/score_gauge_widget.dart';
import 'package:neuro_app/presentation/result/widgets/state_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/messages/dialogs/conform_dialog.dart';
import '../../../core/widgets/ui/icons/switch_theme_icon_widget.dart';
import '../../../features/results/data/responses/get_result_response.dart';
import '../widgets/questions_sheet_builder.dart';

class ExploreResultView extends StatefulWidget {
  final ExploreResultViewArguments arguments;

  const ExploreResultView({super.key, required this.arguments});

  @override
  State<ExploreResultView> createState() => _ExploreResultViewState();
}

class _ExploreResultViewState extends State<ExploreResultView> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreResultBloc>().add(
        ExploreResultInitialize(resultId: widget.arguments.resultId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.resultTitle),
        leading: CloseIconWidget(),
        actions: [
          if (kDebugMode) SwitchThemeIconWidget(),
          RetryIconWidget(
            onPressed: () {
              showConformDialog(
                context: context,
                title: context.l10n.resultRetryTestDialogTitle,
                body: context.l10n.resultRetryTestDialogBody,
                action: context.l10n.buttonsRetryTest,
                onConform: () {
                  context.pushReplacementNamed(
                    Routes.fetchCustomQuestions.name,
                    queryParameters:
                        FetchCustomQuestionsArguments(
                          resultId: widget.arguments.resultId,
                        ).toQueryParameters(),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: Paddings.screenSidesPadding,
        child: BlocConsumer<ExploreResultBloc, ExploreResultState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.status == ExploreResultStatus.loaded) {
              return _ExploreResultDetailsView(state: state, arguments: widget.arguments);
            } else if (state.status == ExploreResultStatus.failure) {
              return _ExploreResultFailureView(
                state: state,
                onRetry: () {
                  context.read<ExploreResultBloc>().add(const ExploreResultLoadResultDetails());
                },
              );
            }
            return const _ExploreResultLoadingView();
          },
        ),
      ),
    );
  }
}

class _ExploreResultDetailsView extends StatelessWidget {
  const _ExploreResultDetailsView({required this.state, required this.arguments});
  final ExploreResultViewArguments arguments;
  final ExploreResultState state;

  @override
  Widget build(BuildContext context) {
    final intScore = state.response!.result.score.clamp(0, 100);

    return SingleChildScrollView(
      padding: Paddings.listViewPadding,
      child: Column(
        spacing: SpacesResources.s2,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Score gauge
          StaggeredItemWrapperWidget(
            position: 0,
            child: ScoreGauge(
              percentage: intScore / 100,
              displayText: '${intScore.toStringAsFixed(0)}%',
              correctAnswers: state.response!.result.correctAnswers,
              wrongAnswers: state.response!.result.wrongAnswers,
              skippedAnswers: 0,
              timeTaken: Duration(seconds: state.response!.result.durationSeconds),
            ),
          ),
          SizedBox(height: SpacesResources.s10),

          ///
          StaggeredItemWrapperWidget(
            position: 1,
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatChip(
                          iconPath: UIImagesResources.checkRoundedUIIcon,
                          title: '${state.response!.result.correctAnswers}',
                          subtitle: context.l10n.resultCorrectCardSubtitle,
                          iconColor: Theme.of(context).extension<ExtraColors>()!.green,
                        ),
                      ),

                      Expanded(
                        child: StatChip(
                          iconPath: UIImagesResources.arrowSquareOutUIIcon,
                          title: '${state.response!.result.totalQuestions}',
                          subtitle: context.l10n.resultCountCardSubtitle,
                          onTap: () {
                            showAppBottomSheet(
                              context: context,
                              child: QuestionsSheetBuilder(resultId: state.response!.result.id),
                            );
                          },
                        ),
                      ),

                      Expanded(
                        child: StatChip(
                          iconPath: UIImagesResources.cancelRoundedUIIcon,
                          title: '${state.response!.result.wrongAnswers}',
                          subtitle: context.l10n.resultWrongCardSubtitle,
                          iconColor: Theme.of(context).extension<ExtraColors>()!.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Previous results
          StaggeredItemWrapperWidget(
            position: 3,
            child: PreviousResultsListCardWidget(results: state.response!.previousResults ?? []),
          ),
        ],
      ),
    );
  }
}

// Failure State View Template
class _ExploreResultFailureView extends StatelessWidget {
  const _ExploreResultFailureView({required this.state, required this.onRetry});

  final ExploreResultState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorStateBodyWidget(
      title: 'فشل في الحصول على النتيجة',
      failure: state.failure!,
      onRetry: onRetry,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

class _ExploreResultLoadingView extends StatelessWidget {
  const _ExploreResultLoadingView();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: _ExploreResultDetailsView(
        state: ExploreResultState(
          status: ExploreResultStatus.loaded,
          response: GetResultResponse(
            result: Result.mock(),
            previousResults: List.generate(5, (index) => Result.mock()),
          ),
        ),
        arguments: ExploreResultViewArguments(resultId: 1),
      ),
    );
  }
}
