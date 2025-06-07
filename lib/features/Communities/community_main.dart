import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'data/repositories/community_repository_impl.dart';
import 'domain/repo/community_repository.dart';
import 'presentation/cubit/community_cubit.dart';
import 'presentation/cubit/community_member_cubit.dart';
import 'presentation/cubit/community_message_cubit.dart';

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
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Communities',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Communities Coming Soon',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Join interest-based communities to chat, post, and engage with like-minded people.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
} 