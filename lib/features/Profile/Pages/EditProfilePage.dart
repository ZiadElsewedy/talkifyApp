import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';

class EditProfilePage extends StatefulWidget {
   EditProfilePage({super.key, required this.user});

 final ProfileUser user ;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final BioTextcontroller = TextEditingController();
  void UpdateProfilePage () async{
     final profilecubit = context.read<ProfileCubit>();
    // Call the updateProfile method from the ProfileCubit
   if (BioTextcontroller.text.isNotEmpty) {
  profilecubit.updateUserProfile(
   widget.user.id , BioTextcontroller.text , 
    widget.user.profilePictureUrl
     
      
   );
}
    
  }

  Widget buildEditPage ( { double uploadProgress = 0.0}) {
    // Initialize the text controller with the current bio
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MyTextField(controller: BioTextcontroller,
             hintText: widget.user.bio.isEmpty ? "Empty bio .." : widget.user.bio,
              obsecureText:false ),
            
             SizedBox(height: 20),
             // last update from ziad 
      ])
        ),
      );
  }

  //build UI
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
         Navigator.pop(context); // Close the edit profile page
  
        }},
      builder: (context, state) {
        // profile loading state
        if (state is ProfileLoadingState) {
          return const Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child:ProfessionalCircularProgress()
                ),
                SizedBox(height: 20),
                Text("Loading..."),
              ],
            ),
          );
        } 
        // profile loaded state
      return buildEditPage();
      },
    );
  }
}