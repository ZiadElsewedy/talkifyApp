import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Search_cubit.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Searchstates.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:lottie/lottie.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late SearchCubit _searchCubit;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Define color constants
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _searchCubit = context.read<SearchCubit>();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _searchCubit.searchUsers(query);
    if (query.isNotEmpty) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;
    final appBarBg = isDarkMode ? colorScheme.surface : Colors.white;
    final appBarText = colorScheme.inversePrimary;
    final searchBg = isDarkMode ? Colors.grey[900]! : lightGrey;
    final searchBorder = isDarkMode ? Colors.grey[800]! : mediumGrey;
    final searchText = isDarkMode ? Colors.white : primaryBlack;
    final searchHint = isDarkMode ? Colors.grey[500]! : darkGrey;
    final searchIcon = isDarkMode ? Colors.grey[400]! : darkGrey;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardBorder = isDarkMode ? Colors.grey[800]! : mediumGrey;
    final avatarBg = isDarkMode ? Colors.grey[800]! : lightGrey;
    final nameText = isDarkMode ? Colors.white : primaryBlack;
    final descText = isDarkMode ? Colors.grey[400]! : darkGrey;
    final divider = isDarkMode ? Colors.grey[800]! : mediumGrey;
    final iconColor = isDarkMode ? Colors.grey[400]! : darkGrey;
    final infoText = isDarkMode ? Colors.grey[300]! : darkGrey;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: searchBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: searchBorder, width: 1),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: searchText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(
                color: searchHint,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: searchIcon,
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: searchIcon,
                        size: 22,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _performSearch,
          ),
        ),
        iconTheme: IconThemeData(color: appBarText),
        titleTextStyle: TextStyle(color: appBarText, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 350,
                    height: 350,
                    child: Lottie.asset(
                      'lib/assets/Search.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Searching...',
                    style: TextStyle(
                      color: infoText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is SearchLoaded) {
            if (state.users.isEmpty) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: iconColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(
                          color: infoText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: _buildUserCard(user, cardBg, cardBorder, avatarBg, nameText, descText, divider),
                  );
                },
              ),
            );
          } else if (state is SearchError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: iconColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: infoText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 350,
                  height: 350,
                  child: Lottie.asset(
                    'lib/assets/Search.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter a name to search',
                  style: TextStyle(
                    color: infoText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(ProfileUser user, Color cardBg, Color cardBorder, Color avatarBg, Color nameText, Color descText, Color divider) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(
            color: divider,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: user.id),
              ),
            ).then((_) {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: avatarBg,
                    backgroundImage: user.profilePictureUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePictureUrl)
                        : null,
                    child: user.profilePictureUrl.isEmpty
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              color: nameText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          color: nameText,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (user.HintDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.HintDescription,
                          style: TextStyle(
                            color: descText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}