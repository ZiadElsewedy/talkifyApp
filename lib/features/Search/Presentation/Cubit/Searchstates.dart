  import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

  abstract class SearchState {}

  class SearchInitial extends SearchState {}

  class SearchLoading extends SearchState {}


  class SearchLoaded extends SearchState {
    final List<ProfileUser> users;
    SearchLoaded({required this.users});
  }

  class SearchError extends SearchState {
    final String message;
    SearchError({required this.message});
  }
