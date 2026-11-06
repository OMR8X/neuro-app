import 'package:neuro_app/core/extensions/build_context_l10n.dart';
import 'package:neuro_app/core/widgets/ui/icons/close_icon_widget.dart';
import 'package:neuro_app/features/tests/domain/entities/question.dart';
import 'package:neuro_app/features/tests/domain/entities/option.dart';
import 'package:neuro_app/features/tests/domain/entities/test_mode.dart';
import 'package:neuro_app/core/services/router/app_arguments.dart';

import 'package:neuro_app/core/resources/styles/spacing_resources.dart';
import 'package:neuro_app/core/resources/styles/spaces_resources.dart';
import 'package:neuro_app/core/widgets/ui/fields/bottom_buttons_widget.dart';
import 'package:neuro_app/presentation/tests/widgets/question_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neuro_app/presentation/quizzing/blocs/quizzing_bloc.dart';

class TestingView extends StatelessWidget {
  const TestingView({super.key, this.arguments});

  final QuizzingArguments? arguments;

  @override
  Widget build(BuildContext context) {
    final questions = arguments?.questions ?? _sampleQuestions();
    final testMode = arguments?.testMode ?? TestMode.testing;

    return BlocProvider<QuizzingBloc>(
      create:
          (_) =>
              QuizzingBloc()..add(
                InitializeQuiz(
                  questions: questions.cast(),
                  lessonId: arguments?.lessonIds?.length == 1 ? arguments!.lessonIds!.first : null,
                  testMode: testMode,
                ),
              ),
      child: Scaffold(
        appBar: AppBar(
          // Using existing localization keys: reuse testProperties title for now
          title: Text("sl<LocalizationManager>().get(LocalizationKeys.testProperties.title)"),
          centerTitle: true,
          leading: CloseIconWidget(),
        ),
        body: Padding(
          padding: Paddings.screenSidesPadding,
          child: Column(
            children: [
              const SizedBox(height: SpacesResources.s4),
              Expanded(
                child: ListView.separated(
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: SpacesResources.s3),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuestionCardWidget(question: question),
                        const SizedBox(height: SpacesResources.s2),
                        // ...question.options.map((option) {
                        //   return OptionMultipleChoicesCardWidget(
                        //     option: option,
                        //     questionAnswer: null,
                        //     testMode: testMode,
                        //     onTap: (_) {},
                        //   );
                        // }),
                      ],
                    );
                  },
                ),
              ),
              BottomButtonWidget(onPressed: () {}, text: context.l10n.buttonsNext),
              const SizedBox(height: SpacesResources.s2),
            ],
          ),
        ),
      ),
    );
  }

  List<Question> _sampleQuestions() {
    return [
      Question(
        id: 1,
        lessonId: 1,
        content: 'Sample question 1: What is 2 + 2?',
        options: [
          const Option(id: 1, questionId: 1, content: '3', isCorrect: false),
          const Option(id: 2, questionId: 1, content: '4', isCorrect: true),
          const Option(id: 3, questionId: 1, content: '5', isCorrect: false),
          const Option(id: 4, questionId: 1, content: '6', isCorrect: false),
        ],
        hintContent: null,
        categoryId: null,
      ),
      Question(
        id: 2,
        lessonId: 1,
        content: 'Sample question 2: Which is a prime number?',
        options: [
          const Option(id: 5, questionId: 2, content: '4', isCorrect: false),
          const Option(id: 6, questionId: 2, content: '6', isCorrect: false),
          const Option(id: 7, questionId: 2, content: '7', isCorrect: true),
          const Option(id: 8, questionId: 2, content: '8', isCorrect: false),
        ],
        hintContent: null,
        categoryId: null,
      ),
    ];
  }
}
