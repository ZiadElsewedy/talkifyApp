import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'data/repositories/community_repository_impl.dart';
import 'domain/repo/community_repository.dart';
import 'presentation/cubit/community_cubit.dart';
import 'presentation/cubit/community_member_cubit.dart';
import 'presentation/cubit/community_message_cubit.dart';
import 'presentation/screens/community_home_page.dart'; // Import the community home page
import 'presentation/screens/community_events_page.dart'; // Import the community events page

/// The main entry point for the Community feature
/// This can be called from other parts of the app to navigate to the communities page
class CommunityMain extends StatelessWidget {
  const CommunityMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CommunityRepository>(
          create: (context) => CommunityRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CommunityCubit>(
            create: (context) => CommunityCubit(
              repository: context.read<CommunityRepository>(),
            ),
          ),
          BlocProvider<CommunityMemberCubit>(
            create: (context) => CommunityMemberCubit(
              repository: context.read<CommunityRepository>(),
            ),
          ),
          BlocProvider<CommunityMessageCubit>(
            create: (context) => CommunityMessageCubit(
              repository: context.read<CommunityRepository>(),
            ),
          ),
        ],
        child: const CommunityScreen(),
      ),
    );
  }
}

/// The main screen for the Communities feature
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid "Build scheduled during frame" error
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Load communities or perform any initialization
      _loadCommunities();
    });
  }
  
  void _loadCommunities() {
    // Load communities from the cubit
    context.read<CommunityCubit>().getAllCommunities();
    
    // Wait for a moment to simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Simply return the CommunityHomePage directly instead of wrapping it in a Scaffold
    // This prevents duplicate AppBars from showing
    return _isLoading 
      ? Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        )
      : const CommunityHomePage();
  }
} 