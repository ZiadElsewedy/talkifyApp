import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/Pages/EditProfilePage.dart';
import 'package:talkifyapp/features/Profile/Pages/components/Bio.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});
  final String? userId; // Optional user ID parameter for the profile page
  // Constructor to initialize the user ID if needed
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthCubit authCubit;
  late ProfileCubit profileCubit;
  late AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    authCubit = BlocProvider.of<AuthCubit>(context);
    profileCubit = BlocProvider.of<ProfileCubit>(context);
    profileCubit.fetchUserProfile(widget.userId!);
    // Fetch the current user from the AuthCubit
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoadedState) {
          final user = state.profileuser;
          return Scaffold(
            appBar: AppBar(
              title:  Text(user.name , style: const TextStyle(color: Color.fromARGB(255, 95, 95, 95)),),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Color.fromARGB(255, 95, 95, 95),),
                  onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) =>  EditProfilePage( user: user,)));
                    // Handle edit button press
                  },
                ),
              ],
              centerTitle: true,
              
            ),
            body: Center(
              child: Column(
                children: [
                     Text(user.email , style: const TextStyle(color: Color.fromARGB(255, 95, 95, 95), fontSize: 20 , ) ,),
                      const SizedBox(height: 20,),
                     CachedNetworkImage(
                            imageUrl: user.profilePictureUrl,
                            placeholder: (context, url) => const Center(child: ProfessionalCircularProgress()),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 72),
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 100,
                              backgroundImage: imageProvider,
                            ),
                          ) 
                    , 
                      const SizedBox(height: 20,),
                      Text('Bio' , style: TextStyle(color: Color.fromARGB(255, 95, 95, 95), fontSize: 20 , ) ,),
                      Mybio(bioText: user.bio),          
                      Text('Posts' , style: TextStyle(color: Color.fromARGB(255, 95, 95, 95), fontSize: 20 , ) ,),
                ],
              ),
            ) ,
          );
        } else if (state is ProfileLoadingState) {
          return const Center(
            child: ProfessionalCircularProgress(),
          );
        } else if (state is ProfileErrorState) {
          return Center(
            child: Text(state.error),
          );
        }
        // Default return to satisfy the linter
        return const SizedBox.shrink();
      },
    );
  }
}