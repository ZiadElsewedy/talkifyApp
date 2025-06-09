import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talkifyapp/features/Storage/Data/Filebase_Storage_repo.dart';
import '../../data/models/community_model.dart';
import '../cubit/community_cubit.dart';
import '../cubit/community_state.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({Key? key}) : super(key: key);

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isPrivate = false;
  File? _selectedImage;
  bool _isUploading = false;

  final List<String> _categories = [
    'General',
    'Technology',
    'Art',
    'Gaming',
    'Music',
    'Sports',
    'Education',
    'Fitness',
    'Food',
    'Travel',
    'Movies',
    'Books',
    'Fashion',
    'Photography',
    'Cars',
    'Business',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String> _uploadImage() async {
    if (_selectedImage == null) return '';
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final storage = FirebaseStorageRepo();
      final path = 'communities/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await storage.uploadFile(_selectedImage!.path, path) ?? '';
      
      setState(() {
        _isUploading = false;
      });
      
      return url;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return '';
    }
  }

  void _createCommunity() async {
    if (_formKey.currentState!.validate()) {
      String iconUrl = '';
      
      if (_selectedImage != null) {
        iconUrl = await _uploadImage();
      }
      
      final currentUser = context.read<AuthCubit>().GetCurrentUser();
      final userId = currentUser?.id ?? 'current_user_id';
      
      final community = CommunityModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        iconUrl: iconUrl,
        rulesPictureUrl: '',
        memberCount: 1,
        createdBy: userId,
        isPrivate: _isPrivate,
        createdAt: DateTime.now(),
      );

      context.read<CommunityCubit>().createCommunity(community);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Community',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<CommunityCubit, CommunityState>(
        listener: (context, state) {
          if (state is CommunityCreatedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Community created successfully!'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
            Navigator.pop(context);
          } else if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community icon
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _selectedImage == null 
                                ? isDark ? Colors.grey.shade800 : Colors.grey.shade200 
                                : null,
                            shape: BoxShape.circle,
                            image: _selectedImage != null 
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  ) 
                                : null,
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: _selectedImage == null 
                              ? Center(
                                  child: Icon(
                                    Icons.people,
                                    color: theme.colorScheme.primary,
                                    size: 60,
                                  ),
                                ) 
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Community Name
                  Text(
                    'Community Name',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _nameController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Enter community name',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a community name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _descriptionController,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your community',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Category
                  Text(
                    'Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                        style: theme.textTheme.bodyMedium,
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Privacy settings
                  SwitchListTile(
                    title: Text(
                      'Private Community',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Private communities require approval to join',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _isPrivate,
                    activeColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32.0),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: state is CommunityCreating ? null : _createCommunity,
                      child: state is CommunityCreating
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onPrimary,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text('CREATE COMMUNITY'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 