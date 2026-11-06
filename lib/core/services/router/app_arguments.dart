// 'equatable' not required here
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_app/features/tests/domain/entities/question.dart';
import 'package:neuro_app/features/tests/domain/entities/test_mode.dart';
import 'package:neuro_app/features/settings/domain/entities/motivational_quote.dart';
import 'package:neuro_app/features/tests/domain/entities/lesson.dart';

class ExploreManagerViewArguments {
  final String title;
  final List<dynamic> items;
  final String Function(dynamic t) itemName;
  final String Function(dynamic t) itemDetails;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;
  final VoidCallback onCreate;

  const ExploreManagerViewArguments({
    required this.title,
    required this.items,
    required this.itemName,
    required this.itemDetails,
    required this.onDelete,
    required this.onEdit,
    required this.onCreate,
  });
}

class LessonsViewArguments {
  final int unitId;

  const LessonsViewArguments({required this.unitId});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory LessonsViewArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as LessonsViewArguments;
    }
    return LessonsViewArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory LessonsViewArguments.fromQueryParameters(Map<String, String> params) {
    final unitId = int.tryParse(params['unitId'] ?? '');
    if (unitId == null) {
      throw ArgumentError('unitId is required and must be a valid integer');
    }
    return LessonsViewArguments(unitId: unitId);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    return {'unitId': unitId.toString()};
  }
}

class PickLessonsArguments {
  final int unitId;

  const PickLessonsArguments({required this.unitId});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory PickLessonsArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as PickLessonsArguments;
    }
    return PickLessonsArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory PickLessonsArguments.fromQueryParameters(Map<String, String> params) {
    final unitId = int.tryParse(params['unitId'] ?? '');
    if (unitId == null) {
      throw ArgumentError('unitId is required and must be a valid integer');
    }
    return PickLessonsArguments(unitId: unitId);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    return {'unitId': unitId.toString()};
  }
}

class TestModeSettingsArguments {
  final List<int>? unitIds;
  final List<int>? lessonIds;

  const TestModeSettingsArguments({this.unitIds, this.lessonIds});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory TestModeSettingsArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as TestModeSettingsArguments;
    }
    return TestModeSettingsArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory TestModeSettingsArguments.fromQueryParameters(Map<String, String> params) {
    List<int>? unitIds;
    List<int>? lessonIds;

    if (params['unitIds']?.isNotEmpty == true) {
      unitIds =
          params['unitIds']!
              .split(',')
              .map((id) => int.tryParse(id.trim()))
              .whereType<int>()
              .toList();
    }

    if (params['lessonIds']?.isNotEmpty == true) {
      lessonIds =
          params['lessonIds']!
              .split(',')
              .map((id) => int.tryParse(id.trim()))
              .whereType<int>()
              .toList();
    }

    return TestModeSettingsArguments(unitIds: unitIds, lessonIds: lessonIds);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (unitIds?.isNotEmpty == true) {
      params['unitIds'] = unitIds!.join(',');
    }
    if (lessonIds?.isNotEmpty == true) {
      params['lessonIds'] = lessonIds!.join(',');
    }
    return params;
  }
}

class QuizzingArguments {
  final List<Question>? questions;
  final TestMode? testMode;
  final List<int>? lessonIds;

  const QuizzingArguments({this.questions, this.testMode, this.lessonIds});
}

class SearchViewArguments {
  final int? unitId;
  final String? heroTag;

  const SearchViewArguments({this.unitId, this.heroTag});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory SearchViewArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as SearchViewArguments;
    }
    return SearchViewArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory SearchViewArguments.fromQueryParameters(Map<String, String> params) {
    final unitId = int.tryParse(params['unitId'] ?? '');
    final heroTag = params['heroTag'];
    return SearchViewArguments(unitId: unitId, heroTag: heroTag);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (unitId != null) {
      params['unitId'] = unitId.toString();
    }
    if (heroTag != null) {
      params['heroTag'] = heroTag!;
    }
    return params;
  }
}

class ExploreResultViewArguments {
  final int resultId;

  const ExploreResultViewArguments({required this.resultId});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory ExploreResultViewArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as ExploreResultViewArguments;
    }
    return ExploreResultViewArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory ExploreResultViewArguments.fromQueryParameters(Map<String, String> params) {
    final resultId = int.tryParse(params['resultId'] ?? '');
    if (resultId == null) {
      throw ArgumentError('resultId is required and must be a valid integer');
    }
    return ExploreResultViewArguments(resultId: resultId);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    return {'resultId': resultId.toString()};
  }
}

class FetchCustomQuestionsArguments {
  final int? resultId;
  final List<int>? questionIds;

  const FetchCustomQuestionsArguments({this.resultId, this.questionIds});

  /// Factory constructor to create arguments from GoRouter state
  /// Uses extra if available, otherwise falls back to query parameters
  factory FetchCustomQuestionsArguments.fromState(GoRouterState state) {
    if (state.extra != null) {
      return state.extra as FetchCustomQuestionsArguments;
    }
    return FetchCustomQuestionsArguments.fromQueryParameters(state.uri.queryParameters);
  }

  /// Factory constructor to create arguments from URL query parameters
  factory FetchCustomQuestionsArguments.fromQueryParameters(Map<String, String> params) {
    final resultId = int.tryParse(params['resultId'] ?? '');
    List<int>? questionIds;

    if (params['questionIds']?.isNotEmpty == true) {
      questionIds =
          params['questionIds']!
              .split(',')
              .map((id) => int.tryParse(id.trim()))
              .whereType<int>()
              .toList();
    }

    return FetchCustomQuestionsArguments(resultId: resultId, questionIds: questionIds);
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (resultId != null) {
      params['resultId'] = resultId.toString();
    }
    if (questionIds?.isNotEmpty == true) {
      params['questionIds'] = questionIds!.join(',');
    }
    return params;
  }
}

class MotivationalQuoteArguments {
  final MotivationalQuote quote;

  const MotivationalQuoteArguments({required this.quote});
}

class ExploreAnswersEvaluationsViewArguments {
  final int resultId;

  const ExploreAnswersEvaluationsViewArguments({required this.resultId});
}

