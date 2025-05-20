import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Search/Domain/SearchRepo.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Searchstates.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepo searchRepo;

  SearchCubit({required this.searchRepo}) : super(SearchInitial());

  void searchUsers(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    try {
      emit(SearchLoading());
      final users = await searchRepo.searchUsers(query);
      emit(SearchLoaded(users: users));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
