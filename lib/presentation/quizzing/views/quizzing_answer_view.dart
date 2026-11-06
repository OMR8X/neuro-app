import 'package:neuro_app/core/injector/tests_feature_inj.dart';
import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/widgets/animations/staggered_item_wrapper_widget.dart';
import 'package:neuro_app/features/settings/domain/entities/app_settings.dart';
import 'package:neuro_app/features/tests/domain/entities/question_answer.dart';
import 'package:neuro_app/features/tests/domain/entities/question_category.dart';
import 'package:neuro_app/presentation/quizzing/widgets/Orderable_options_builder_widget.dart';
import 'package:neuro_app/presentation/quizzing/widgets/multiple_choices_options_builder_widget.dart';
import 'package:neuro_app/presentation/quizzing/widgets/textual_options_builder_widget.dart';
import 'package:neuro_app/presentation/tests/widgets/question_card_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:neuro_app/presentation/tests/widgets/quizzing_answer_top_controls.dart';
import 'package:neuro_app/presentation/tests/widgets/quizzing_answer_navigation.dart';
import 'package:neuro_app/core/resources/styles/spaces_resources.dart';
import 'package:neuro_app/presentation/quizzing/blocs/quizzing_bloc.dart';
import 'package:neuro_app/features/tests/domain/entities/test_mode.dart';

class QuizzingAnswerView extends StatelessWidget {
  const QuizzingAnswerView({
    super.key,
    required this.state,
    required this.testMode,
    required this.onClose,
    required this.onNextOrSubmit,
  });

  final QuizzingAnswerQuestion state;
  final TestMode testMode;
  final VoidCallback onClose;
  final VoidCallback onNextOrSubmit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: Paddings.listViewPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SpacesResources.s4,
            children: [
              // SizedBox(height: SizesResources.iconButtonAppBarHeight,),
              /// Top Controllers
              BlocBuilder<QuizzingBloc, QuizzingState>(
                buildWhen: (previous, current) {
                  if (previous is QuizzingAnswerQuestion && current is QuizzingAnswerQuestion) {
                    return previous.elapsedTime != current.elapsedTime;
                  }
                  return false;
                },
                builder: (context, state) {
                  return QuizzingAnswerTopControls(
                    elapsedTime: state is QuizzingAnswerQuestion ? state.elapsedTime : Duration.zero,
                    current: state is QuizzingAnswerQuestion ? state.currentQuestionIndex + 1 : 0,
                    total: state is QuizzingAnswerQuestion ? state.totalQuestions : 0,
                    onClose: onClose,
                  );
                },
              ),

              /// Question Card
              QuestionCardWidget(question: state.currentQuestion),

              /// Content options
              BlocBuilder<QuizzingBloc, QuizzingState>(
                buildWhen: (previous, current) {
                  if (previous is QuizzingAnswerQuestion && current is QuizzingAnswerQuestion) {
                    final con1 = previous.selectedAnswers != current.selectedAnswers;
                    final con2 = previous.currentQuestion != current.currentQuestion;
                    return con1 || con2;
                  }
                  return false;
                },
                builder: (context, state) {
                  if (state is! QuizzingAnswerQuestion) return const SizedBox.shrink();
                  return _buildOptions(
                    context: context,
                    state: state,
                    testMode: testMode,
                  );
                },
              ),
            ],
          ),
        ),

        // Only show navigation when user has selected an answer for current question
        BlocBuilder<QuizzingBloc, QuizzingState>(
          buildWhen: (previous, current) {
            if (previous is QuizzingAnswerQuestion && current is QuizzingAnswerQuestion) {
              return previous.selectedAnswers.length != current.selectedAnswers.length;
            }
            return false;
          },
          builder: (context, state) {
            debugPrint("rebuild action buttons");
            return _buildActionButtons(context, state as QuizzingAnswerQuestion);
          },
          
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, QuizzingAnswerQuestion state) {
    bool canSubmit = state.currentQuestion.questionAnswers.isNotEmpty;
    bool canGoPrevious = state.canGoPrevious;
    bool canGoNext = state.canGoNext;

    ///
    final QuestionCategory? category = sl<AppSettings>().categories.firstWhereOrNull(
      (c) => c.id == state.currentQuestion.categoryId,
    );

    ///
    if ((category?.isOrderable ?? false)) {
      canGoNext = true;
    } else if ((category?.isMCQ ?? false)) {
      canGoNext = state.selectedAnswers.isNotEmpty;
    } else if (((category?.isTypeable) ?? false) || ((category?.isSingleAnswer) ?? false)) {
      canGoNext = state.selectedAnswers.length == state.currentQuestion.options.length;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: StaggeredItemWrapperWidget(
          position: 1,
          child: QuizzingAnswerNavigation(
            canGoPrevious: canGoPrevious,
            canGoNext: canGoNext,
            onPrevious: () => context.read<QuizzingBloc>().add(const PreviousQuestion()),
            onNextOrSubmit: onNextOrSubmit,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions({
    required BuildContext context,
    required QuizzingAnswerQuestion state,
    required TestMode testMode,
  }) {
    ///
    final QuestionCategory? category = sl<AppSettings>().categories.firstWhereOrNull(
      (c) => c.id == state.currentQuestion.categoryId,
    );

    ///
    if (category?.isMCQ ?? false) {
      return MultipleChoicesQuestionBuilderWidget(
        testMode: testMode,
        question: state.currentQuestion,
        questionsAnswers: state.selectedAnswers,
        onSelectOption: (option) {
          ///
          context.read<QuizzingBloc>().add(
            UpdateMCQQuestionAnswersEvent(
              answers: [QuestionAnswer(questionId: state.currentQuestion.id, optionId: option.id)],
            ),
          );
        },
      );
    } else if (category?.isOrderable ?? false) {
      return OrderableQuestionBuilderWidget(
        testMode: testMode,
        question: state.currentQuestion,
        questionsAnswers: state.selectedAnswers,
        onSubmitOrder: (answers) {
          context.read<QuizzingBloc>().add(UpdateOrderableQuestionAnswersEvent(answers: answers));
        },
      );
    } else if ((category?.isTypeable) ?? false) {
      return TextualQuestionsBuilderWidget(
        testMode: testMode,
        question: state.currentQuestion,
        questionsAnswers: state.selectedAnswers,
        onSubmitText: (option, value) {
          context.read<QuizzingBloc>().add(
            UpdateTextualQuestionAnswersEvent(
              answers: [
                QuestionAnswer(
                  questionId: state.currentQuestion.id,
                  answerText: value,
                  optionId: option.id,
                ),
              ],
            ),
          );
        },
      );
    } else if ((category?.isSingleAnswer) ?? false) {
      return TextualQuestionsBuilderWidget(
        testMode: testMode,
        question: state.currentQuestion,
        questionsAnswers: state.selectedAnswers,
        onSubmitText: (option, value) {
          ///
          context.read<QuizzingBloc>().add(
            UpdateTextualQuestionAnswersEvent(
              answers: [
                QuestionAnswer(
                  questionId: state.currentQuestion.id,
                  answerText: value,
                  optionId: option.id,
                ),
              ],
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
