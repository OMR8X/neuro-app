import 'package:neuro_app/core/extensions/build_context_l10n.dart';
import 'package:neuro_app/core/resources/errors/error_mapper.dart';
import 'package:neuro_app/core/injector/app_injection.dart';
import 'package:neuro_app/core/resources/styles/sizes_resources.dart';
import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/widgets/animations/staggered_list_wrapper_widget.dart';
import 'package:neuro_app/features/settings/domain/entities/app_settings.dart';
import 'package:neuro_app/features/tests/domain/entities/question.dart';
import 'package:neuro_app/features/results/domain/requests/get_result_questions_details_request.dart';
import 'package:neuro_app/presentation/quizzing/widgets/multiple_choices_options_builder_widget.dart';
import 'package:neuro_app/presentation/quizzing/widgets/orderable_options_builder_widget.dart';
import 'package:neuro_app/presentation/quizzing/widgets/textual_options_builder_widget.dart';
import 'package:neuro_app/presentation/tests/widgets/question_card_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/resources/errors/failures.dart';
import '../../../core/widgets/ui/states/error_state_body_widget.dart';
import '../../../features/tests/domain/entities/question_answer.dart';
import '../../../features/tests/domain/entities/question_category.dart' show QuestionCategory;
import '../../../features/tests/domain/entities/test_mode.dart';
import '../../../features/results/domain/usecases/get_result_questions_details_use_case.dart';

class QuestionsSheetBuilder extends StatefulWidget {
  const QuestionsSheetBuilder({super.key, required this.resultId});
  final int resultId;
  @override
  State<QuestionsSheetBuilder> createState() => _QuestionsSheetBuilderState();
}

class _QuestionsSheetBuilderState extends State<QuestionsSheetBuilder> {
  final GlobalKey menuKey = GlobalKey();

  late Failure? _failure;
  late bool _isLoading;
  late List<Question> _questions;

  @override
  void initState() {
    ///
    _isLoading = true;
    _failure = null;
    _questions = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestions();
    });
    super.initState();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await sl<GetResultQuestionsDetailsUsecase>().call(
        GetResultQuestionsDetailsRequest(resultId: widget.resultId),
      );
      response.fold(
        (l) => _failure = l,
        (r) {
          _failure = null;
          _questions = r.resultQuestions;
        },
      );
    } catch (e) {
      _failure = errorToFailure(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Skeletonizer(
        child: _loadedBody(List.generate(5, (index) => Question.mock())),
      );
    }
    if (_failure != null) {
      return ErrorStateBodyWidget(
        title: "خطأ في الحصول على الاسئلة",
        failure: _failure,
        onRetry: () {
          setState(() => _isLoading = true);
          _fetchQuestions();
        },
      );
    }

    return _loadedBody(_questions);
  }

  Widget _loadedBody(List<Question> questions) {
    return Column(
      children: [
        // Content
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: Paddings.listViewPadding,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return StaggeredListWrapperWidget(
                  position: index,
                  child: Column(
                    children: [
                      QuestionCardWidget(question: questions[index]),
                      _buildOptions(
                        context: context,
                        question: questions[index],
                        questionAnswers: questions[index].questionAnswers,
                        testMode: TestMode.exploring,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Close button
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: SizesResources.buttonLargeHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.buttonsClose),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions({
    required BuildContext context,
    required Question question,
    required List<QuestionAnswer> questionAnswers,
    required TestMode testMode,
  }) {
    ///
    final QuestionCategory? category = sl<AppSettings>().categories.firstWhereOrNull(
      (c) => c.id == question.categoryId,
    );

    ///
    if (category?.isMCQ ?? false) {
      return MultipleChoicesQuestionBuilderWidget(
        question: question,
        questionsAnswers: questionAnswers,
      );
    } else if (category?.isOrderable ?? false) {
      return OrderableQuestionBuilderWidget(
        question: question,
        questionsAnswers: questionAnswers,
        answerEvaluations: question.answerEvaluations,
      );
    } else if ((category?.isTypeable) ?? false) {
      return TextualQuestionsBuilderWidget(
        question: question,
        questionsAnswers: questionAnswers,
        answerEvaluations: question.answerEvaluations,
      );
    } else if ((category?.isSingleAnswer) ?? false) {
      return TextualQuestionsBuilderWidget(
        question: question,
        questionsAnswers: questionAnswers,
        answerEvaluations: question.answerEvaluations,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
