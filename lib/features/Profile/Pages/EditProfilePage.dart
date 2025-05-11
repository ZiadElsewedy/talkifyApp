import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';

class EditProfilePage extends StatefulWidget {
  EditProfilePage({super.key, required this.user});

  final ProfileUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // mobile image pick 
  PlatformFile? imagePickedFile; // For mobile image pick
  Uint8List? webImage; // For web image pick

  Future<void> pickImage() async {
    // For mobile and web image pick
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        imagePickedFile = result.files.first;
        if (kIsWeb) {
          webImage = result.files.first.bytes; // Get the bytes for web
        }
      });
    }
  }

  final BioTextcontroller = TextEditingController();
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.name; // Pre-fill with current name
    BioTextcontroller.text = widget.user.bio; // Initialize the text controller with the current bio
  }

  void UpdateProfilePage() async {
    final profilecubit = context.read<ProfileCubit>();
    final String id = widget.user.id;
    final imageMoilePath = kIsWeb ? null : imagePickedFile?.path;
    // Call the pickImage method to select an image
    final ImageWebBytes = kIsWeb ? imagePickedFile?.bytes : null;
    final String newBio = BioTextcontroller.text.isNotEmpty ? BioTextcontroller.text : widget.user.bio;
    final String newName = nameController.text.isNotEmpty ? nameController.text : widget.user.name;

    // Call the updateProfile method from the ProfileCubit
    if (imagePickedFile != null || newBio != null) {
      profilecubit.updateUserProfile(
        id: id,
        newName: newName,
        newBio: newBio,
        ImageWebByter: ImageWebBytes,
        imageMobilePath: imageMoilePath,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image or enter a new bio."),
        ),
      );
    }
  }

  Widget buildEditPage() {
    // Initialize the text controller with the current bio
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Call the updateProfile method when the check icon is pressed
              UpdateProfilePage();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Center(
              child: Container(
                height: 200,
                width: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: kIsWeb
                      ? (webImage != null
                          ? Image.memory(webImage!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: widget.user.profilePictureUrl,
                              placeholder: (context, url) => const Center(child: ProfessionalCircularProgress()),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 72),
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: 100,
                                backgroundImage: imageProvider,
                              ),
                            ))
                      : (imagePickedFile != null
                          ? Image.file(File(imagePickedFile!.path!), fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: widget.user.profilePictureUrl,
                              placeholder: (context, url) => const Center(child: ProfessionalCircularProgress()),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 72),
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: 100,
                                backgroundImage: imageProvider,
                              ),
                            )),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bio', style: TextStyle(fontSize: 20)),
            // pick image button 
            Center(
              child: ElevatedButton(
                onPressed: pickImage,
                child: const Text("Pick Image"),
              ),
            ),
            const SizedBox(height: 20),
            MyTextField(
              controller: BioTextcontroller,
              hintText: widget.user.bio.isEmpty ? "Empty bio .." : widget.user.bio,
              obsecureText: false,
            ),
            const SizedBox(height: 20),
            MyTextField(
              controller: nameController,
              hintText: widget.user.name.isEmpty ? "Empty name .." : widget.user.name,
              obsecureText: false,
            ),
            const SizedBox(height: 20),
            // last update from ziad 
          ]),
        ),
      ),
    );
  }

  // build UI
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
          Navigator.pop(context); // Close the edit profile page
        }
      },
      builder: (context, state) {
        // profile loading state
        if (state is ProfileLoadingState) {
          return const Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: ProfessionalCircularProgress()),
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
