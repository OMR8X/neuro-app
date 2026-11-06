part of 'quizzing_bloc.dart';

sealed class QuizzingState extends Equatable {
  const QuizzingState();

  @override
  List<Object?> get props => [];
}

final class QuizzingLoading extends QuizzingState {
  const QuizzingLoading();
}

final class QuizzingAnswerQuestion extends QuizzingState {
  final Question currentQuestion;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Duration elapsedTime;
  final bool canGoNext;
  final bool canGoPrevious;
  final List<QuestionAnswer> selectedAnswers;

  const QuizzingAnswerQuestion({
    required this.currentQuestion,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.elapsedTime,
    required this.canGoNext,
    required this.canGoPrevious,
    this.selectedAnswers = const [],
  });

  QuizzingAnswerQuestion copyWith({
    Question? currentQuestion,
    int? currentQuestionIndex,
    int? totalQuestions,
    Duration? elapsedTime,
    bool? canGoNext,
    bool? canGoPrevious,
    List<QuestionAnswer>? selectedAnswers,
  }) {
    return QuizzingAnswerQuestion(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      canGoNext: canGoNext ?? this.canGoNext,
      canGoPrevious: canGoPrevious ?? this.canGoPrevious,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }

  @override
  List<Object?> get props => [
    currentQuestion,
    currentQuestionIndex,
    totalQuestions,
    elapsedTime,
    canGoNext,
    canGoPrevious,
    selectedAnswers,
  ];
}

final class QuizzingUploadingResult extends QuizzingState {
  const QuizzingUploadingResult();

  @override
  List<Object> get props => [];
}

final class QuizzingFailedUploadingResult extends QuizzingState {
  final Failure failure;
  const QuizzingFailedUploadingResult({required this.failure});

  @override
  List<Object> get props => [];
}

final class QuizzingResultUploaded extends QuizzingState {
  final Result result;
  const QuizzingResultUploaded({required this.result});

  @override
  List<Object> get props => [result];
}
