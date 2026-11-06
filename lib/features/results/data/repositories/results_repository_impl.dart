import 'package:neuro_app/core/resources/errors/error_mapper.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/resources/errors/failures.dart';
import '../../domain/repositories/results_repository.dart';
import '../../domain/requests/add_result_request.dart';
import '../../domain/requests/get_my_results_request.dart';
import '../../domain/requests/get_result_request.dart';
import '../../domain/requests/get_result_leaderboard_request.dart';
import '../../domain/requests/get_result_questions_details_request.dart';
import '../../domain/requests/get_answer_evaluations_request.dart';
import '../responses/add_result_response.dart';
import '../responses/get_results_response.dart';
import '../responses/get_result_response.dart';
import '../responses/get_result_leaderboard_response.dart';
import '../responses/get_result_questions_details_response.dart';
import '../responses/get_answer_evaluations_response.dart';
import '../datasources/results_remote_data_source.dart';

class ResultsRepositoryImpl implements ResultsRepository {
  final ResultsRemoteDataSource remoteDataSource;

  ResultsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AddResultResponse>> addResult(AddResultRequest request) async {
    try {
      final result = await remoteDataSource.addResult(request);
      return Right(result);
    } on Exception catch (e) {
      return Left(errorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GetResultsResponse>> getMyResults(GetMyResultsRequest request) async {
    try {
      final result = await remoteDataSource.getMyResults(request);
      return Right(result);
    } on Exception catch (e) {
      return Left(errorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GetResultResponse>> getResult(GetResultRequest request) async {
    try {
      final result = await remoteDataSource.getResult(request);
      return Right(result);
    } on Exception catch (e) {
      return Left(errorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GetResultLeaderboardResponse>> getResultLeaderboard(
    GetResultLeaderboardRequest request,
  ) async {
    try {
      final result = await remoteDataSource.getResultLeaderboard(request);
      return Right(result);
    } on Exception catch (e) {
      return Left(errorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GetResultQuestionsDetailsResponse>> getResultQuestionsDetails(
    GetResultQuestionsDetailsRequest request,
  ) async {
    try {
      final result = await remoteDataSource.getResultQuestionsDetails(request);
      return Right(result);
    } catch (e) {
      return Left(errorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GetAnswerEvaluationsResponse>> getAnswerEvaluations(
    GetAnswerEvaluationsRequest request,
  ) async {
    try {
      final result = await remoteDataSource.getAnswerEvaluations(request);
      return Right(result);
    } catch (e) {
      return Left(errorToFailure(e));
    }
  }
}
