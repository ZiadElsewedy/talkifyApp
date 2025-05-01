
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

abstract class ProfileStates {} 
class ProfileInitialState extends ProfileStates {}
class ProfileLoadingState extends ProfileStates {}
class ProfileLoadedState extends ProfileStates {
  final ProfileUser profileuser;
  ProfileLoadedState(this.profileuser);
}
class ProfileErrorState extends ProfileStates {
  final String error;
  ProfileErrorState(this.error);
}
