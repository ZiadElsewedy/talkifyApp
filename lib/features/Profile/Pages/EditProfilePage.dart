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
  //build UI
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        // profile loading state
        if (state is ProfileLoadingState) {
          return const Center(child: ProfessionalCircularProgress());
        }
        // profile loaded state
      return buildEditPage();
      },
    );
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
            
      ])
        ),
      );
  }
}