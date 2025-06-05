import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/ProfilePicFunction.dart';

class EditProfilePage extends StatefulWidget {
  EditProfilePage({super.key, required this.user});

  final ProfileUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Profile image pick
  PlatformFile? ProfileimagePickedFile;
  Uint8List? ProfilewebImage;
  
  // Background image pick
  PlatformFile? backgroundImagePickedFile;
  Uint8List? webBackgroundImage;

  // General image picker function
  Future<Map<String, dynamic>?> pickImageGeneral() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    
    if (result != null && result.files.isNotEmpty) {
      return {
        'file': result.files.first,
        'bytes': kIsWeb ? result.files.first.bytes : null,
      };
    }
    return null;
  }

  final BioTextcontroller = TextEditingController();
  final nameController = TextEditingController();
  final hintDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.name;
    BioTextcontroller.text = widget.user.bio;
    hintDescriptionController.text = widget.user.HintDescription;
  }

  void UpdateProfilePage() async {
    final profilecubit = context.read<ProfileCubit>();
    final String id = widget.user.id;
    
    // Profile image paths
    final imageMobilePath = kIsWeb ? null : ProfileimagePickedFile?.path;
    final ImageWebBytes = kIsWeb ? ProfileimagePickedFile?.bytes : null;
    
    // Background image paths
    final backgroundImageMobilePath = kIsWeb ? null : backgroundImagePickedFile?.path;
    final backgroundImageWebBytes = kIsWeb ? backgroundImagePickedFile?.bytes : null;

    final String newBio = BioTextcontroller.text.isNotEmpty ? BioTextcontroller.text : widget.user.bio;
    final String newName = nameController.text.isNotEmpty ? nameController.text : widget.user.name;
    final String newHintDescription = hintDescriptionController.text.isNotEmpty ? hintDescriptionController.text : widget.user.HintDescription;

    if (ProfileimagePickedFile != null || backgroundImagePickedFile != null || newBio != widget.user.bio || newName != widget.user.name || newHintDescription != widget.user.HintDescription) {
      profilecubit.updateUserProfile(
        id: id,
        newName: newName,
        newBio: newBio,
        ImageWebByter: ImageWebBytes,
        imageMobilePath: imageMobilePath,
        backgroundImageWebBytes: backgroundImageWebBytes,
        backgroundImageMobilePath: backgroundImageMobilePath,
        newHintDescription: newHintDescription,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final appBarBg = colorScheme.surface;
    final appBarText = colorScheme.inversePrimary;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardText = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final cardSubText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final iconColor = isDarkMode ? Colors.grey[400]! : Colors.black54;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: UpdateProfilePage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Background Image Section
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      kIsWeb
                          ? (webBackgroundImage != null
                              ? Image.memory(webBackgroundImage!, fit: BoxFit.cover)
                              : CachedNetworkImage(
                                  imageUrl: widget.user.backgroundprofilePictureUrl,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: ProfessionalCircularProgress()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                  ),
                                  fit: BoxFit.cover,
                                ))
                          : (backgroundImagePickedFile != null
                              ? Image.file(File(backgroundImagePickedFile!.path!), fit: BoxFit.cover)
                              : CachedNetworkImage(
                                  imageUrl: widget.user.backgroundprofilePictureUrl,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: ProfessionalCircularProgress()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                  ),
                                  fit: BoxFit.cover,
                                )),
                      // Upload Button Overlay for Background
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            onPressed: () async {
                              final pickedImage = await pickImageGeneral();
                              if (pickedImage != null) {
                                setState(() {
                                  backgroundImagePickedFile = pickedImage['file'];
                                  if (kIsWeb) {
                                    webBackgroundImage = pickedImage['bytes'];
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 28),
                            tooltip: "Change Background",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    ProfilePicFunction(
                      state: context.watch<ProfileCubit>().state,
                      profilePictureUrl: widget.user.profilePictureUrl,
                      pickedFile: ProfileimagePickedFile,
                      webImage: ProfilewebImage,
                      size: 150,
                      showBorder: true,
                      borderColor: Colors.white,
                      borderWidth: 1.2,
                    ),
                    // Profile Picture Upload Button
                    Positioned(
                      bottom: 15,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final pickedImage = await pickImageGeneral();
                            if (pickedImage != null) {
                              setState(() {
                                ProfileimagePickedFile = pickedImage['file'];
                                if (kIsWeb) {
                                  ProfilewebImage = pickedImage['bytes'];
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.add_a_photo, color: Colors.white, size: 14),
                          tooltip: "Change Profile Picture",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bio Section

              const Text('Name', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              MyTextField(
                controller: nameController,
                hintText: widget.user.name.isEmpty ? "Empty name .." : widget.user.name,
                obsecureText: false,
              ),
              const SizedBox(height: 20),
              const Text('Hint Description', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              MyTextField(
                controller: hintDescriptionController,
                hintText: widget.user.HintDescription.isEmpty ? "" : widget.user.HintDescription,
                obsecureText: false,
              ),
              const Text('Bio', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              MyTextField(
                controller: BioTextcontroller,
                hintText: widget.user.bio.isEmpty ? "Empty bio .." : widget.user.bio,
                obsecureText: false,
              ),
              const SizedBox(height: 20),
              // Name Section

              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
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
        return buildEditPage();
      },
    );
  }
}
