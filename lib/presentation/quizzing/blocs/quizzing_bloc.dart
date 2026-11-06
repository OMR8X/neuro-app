import 'package:neuro_app/core/resources/errors/failures.dart';
import 'package:neuro_app/features/tests/domain/entities/question_answer.dart';
import 'package:neuro_app/features/results/domain/entities/result.dart';
import 'package:neuro_app/features/tests/domain/entities/test_mode.dart';
import 'package:neuro_app/features/results/domain/requests/add_result_request.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:neuro_app/features/tests/domain/entities/question.dart';
import 'package:neuro_app/features/results/domain/usecases/add_result_use_case.dart';
import 'package:neuro_app/core/injector/app_injection.dart';

part 'quizzing_event.dart';
part 'quizzing_state.dart';

class QuizzingBloc extends Bloc<QuizzingEvent, QuizzingState> {
  /// Use case to submit results
  final AddResultUsecase _addResultUsecase;

  ///
  QuizzingBloc({AddResultUsecase? addResultUsecase})
    : _addResultUsecase = addResultUsecase ?? sl<AddResultUsecase>(),
      super(QuizzingLoading()) {
    on<InitializeQuiz>(_onInitializeQuiz);
    on<UpdateTextualQuestionAnswersEvent>(_onUpdateTextualQuestionAnswersEvent);
    on<UpdateMCQQuestionAnswersEvent>(_onUpdateMCQQuestionAnswersEvent);
    on<UpdateOrderableQuestionAnswersEvent>(_onUpdateOrderableQuestionAnswersEvent);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<CloseQuiz>(_onCloseQuiz);
    on<SubmitQuiz>(_onSubmitQuiz);
    on<UpdateState>(_onUpdateState);
    on<RetryUploadResult>(_onRetryUploadResult);
  }

  ///
  late TestMode testMode;
  late Timer _timer;
  late DateTime _startTime;
  late int? _lessonId;
  late List<Question> _questions;
  Duration _elapsedTime = Duration.zero;
  late List<QuestionAnswer> _questionsAnswers;

  void _onInitializeQuiz(InitializeQuiz event, Emitter<QuizzingState> emit) {
    ///
    emit(const QuizzingLoading());

    ///
    // Limit questions to a maximum of 15
    _questions = event.questions;
    _lessonId = event.lessonId;
    testMode = event.testMode;
    _questionsAnswers = [];
    _startTime = DateTime.now();
    _elapsedTime = Duration.zero;

    /// Start timer
    _startTimer();

    ///
    emit(
      QuizzingAnswerQuestion(
        currentQuestion: _questions[0],
        currentQuestionIndex: 0,
        totalQuestions: _questions.length,
        elapsedTime: _elapsedTime,
        canGoNext: _questions.length > 1,
        canGoPrevious: false,
        selectedAnswers: _questionsAnswers.where((a) => a.questionId == _questions[0].id).toList(),
      ),
    );
  }

  void _onUpdateTextualQuestionAnswersEvent(
    UpdateTextualQuestionAnswersEvent event,
    Emitter<QuizzingState> emit,
  ) {
    if (state is QuizzingAnswerQuestion) {
      /// Get the current state
      final currentState = state as QuizzingAnswerQuestion;
      final answers = event.answers;

      /// Store the selected answer
      _questionsAnswers.removeWhere((e) {
        return answers.map((e) => e.optionId).contains(e.optionId);
      });
      _questionsAnswers.addAll(answers.where((e) => e.answerText?.isNotEmpty ?? false));

      /// Update the state: include full selectedAnswers map so UI can read per-question answers
      emit(
        currentState.copyWith(
          selectedAnswers:
              _questionsAnswers
                  .where((a) => a.questionId == currentState.currentQuestion.id)
                  .toList(),
        ),
      );
    }
  }

  void _onUpdateMCQQuestionAnswersEvent(
    UpdateMCQQuestionAnswersEvent event,
    Emitter<QuizzingState> emit,
  ) {
    if (state is QuizzingAnswerQuestion) {
      /// Get the current state
      final currentState = state as QuizzingAnswerQuestion;
      final answers = event.answers;

      /// Store the selected answer
      _questionsAnswers
        ..removeWhere((e) {
          return answers.map((e) => e.optionId).contains(e.optionId);
        })
        ..addAll(answers.where((e) => e.optionId != null));

      /// Update the state: include full selectedAnswers map so UI can read per-question answers
      emit(
        currentState.copyWith(
          selectedAnswers:
              _questionsAnswers
                  .where((a) => a.questionId == currentState.currentQuestion.id)
                  .toList(),
        ),
      );
    }
  }

  void _onUpdateOrderableQuestionAnswersEvent(
    UpdateOrderableQuestionAnswersEvent event,
    Emitter<QuizzingState> emit,
  ) {
    if (state is QuizzingAnswerQuestion) {
      /// Get the current state
      final currentState = state as QuizzingAnswerQuestion;
      final answers = event.answers;

      /// Store the selected answer
      _questionsAnswers.removeWhere((e) {
        return answers.map((e) => e.optionId).contains(e.optionId);
      });
      _questionsAnswers.addAll(answers.where((e) => e.answerPosition != null));

      /// Update the state: include full selectedAnswers map so UI can read per-question answers
      emit(
        currentState.copyWith(
          selectedAnswers:
              _questionsAnswers
                  .where((a) => a.questionId == currentState.currentQuestion.id)
                  .toList(),
        ),
      );
    }
  }

  void _onNextQuestion(NextQuestion event, Emitter<QuizzingState> emit) {
    if (state is QuizzingAnswerQuestion) {
      /// Get the current state
      final currentState = state as QuizzingAnswerQuestion;
      final nextIndex = currentState.currentQuestionIndex + 1;

      ///
      if (nextIndex < _questions.length) {
        final nextQuestion = _questions[nextIndex];

        /// Update the state
        emit(
          currentState.copyWith(
            currentQuestionIndex: nextIndex,
            currentQuestion: nextQuestion,
            canGoNext: nextIndex < _questions.length - 1,
            canGoPrevious: true,
            selectedAnswers:
                _questionsAnswers.where((a) => a.questionId == nextQuestion.id).toList(),
          ),
        );
      }
    }
  }

  void _onPreviousQuestion(PreviousQuestion event, Emitter<QuizzingState> emit) {
    if (state is QuizzingAnswerQuestion) {
      /// Get the current state
      final currentState = state as QuizzingAnswerQuestion;

      final previousIndex = currentState.currentQuestionIndex - 1;

      if (previousIndex >= 0) {
        final previousQuestion = _questions[previousIndex];

        emit(
          currentState.copyWith(
            currentQuestionIndex: previousIndex,
            currentQuestion: previousQuestion,
            canGoNext: true,
            canGoPrevious: previousIndex > 0,
            selectedAnswers:
                _questionsAnswers.where((a) => a.questionId == previousQuestion.id).toList(),
          ),
        );
      }
    }
  }

  void _onCloseQuiz(CloseQuiz event, Emitter<QuizzingState> emit) {
    add(const SubmitQuiz());
  }

  Future<void> _onSubmitQuiz(SubmitQuiz event, Emitter<QuizzingState> emit) async {
    emit(const QuizzingUploadingResult());

    /// Stop the timer
    _stopTimer();

    /// Calculate values
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;

    /// Upload the result
    final response = await _addResultUsecase.call(
      AddResultRequest(
        testMode: testMode,
        lessonId: _lessonId,
        durationSeconds: durationSeconds,
        questionsIds: _questions.map((q) => q.id).toList(),
        questionsAnswers: _questionsAnswers,
      ),
    );

    response.fold(
      (failure) {
        emit(QuizzingFailedUploadingResult(failure: failure));
      },
      (response) {
        emit(QuizzingResultUploaded(result: response.result));
      },
    );
  }

  void _onUpdateState(UpdateState event, Emitter<QuizzingState> emit) {
    if (state is QuizzingAnswerQuestion) {
      final currentState = state as QuizzingAnswerQuestion;
      emit(currentState.copyWith(elapsedTime: _elapsedTime));
    }
  }

  void _onRetryUploadResult(RetryUploadResult event, Emitter<QuizzingState> emit) {
    add(const SubmitQuiz());
  }

  void _startTimer() {
    const Duration interval = Duration(seconds: 1);
    _timer = Timer.periodic(interval, (timer) {
      if (state is QuizzingAnswerQuestion) {
        _elapsedTime = DateTime.now().difference(_startTime);
        add(UpdateState());
      }
    });
  }

  void _stopTimer() {
    _timer.cancel();
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
