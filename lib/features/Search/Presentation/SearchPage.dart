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
  final FocusNode _searchFocusNode = FocusNode();
  late SearchCubit _searchCubit;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFocused = false;

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
      duration: const Duration(milliseconds: 400),
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
        curve: Curves.easeOutCubic,
      ),
    );
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    final searchBorder = _isFocused 
        ? (isDarkMode ? colorScheme.primary.withOpacity(0.7) : colorScheme.primary.withOpacity(0.5))
        : (isDarkMode ? Colors.grey[800]! : mediumGrey);
    final searchText = isDarkMode ? Colors.white : primaryBlack;
    final searchHint = isDarkMode ? Colors.grey[500]! : darkGrey;
    final searchIcon = _isFocused
        ? (isDarkMode ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary)
        : (isDarkMode ? Colors.grey[400]! : darkGrey);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: BackButton(color: colorScheme.inversePrimary),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: searchBorder, width: _isFocused ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: _isFocused 
                      ? colorScheme.primary.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: _isFocused ? 8 : 6,
                  offset: const Offset(0, 3),
                  spreadRadius: _isFocused ? 2 : 1,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: searchText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                textAlignVertical: TextAlignVertical.center,
                cursorColor: colorScheme.primary,
                cursorWidth: 1.5,
                cursorRadius: const Radius.circular(4),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(
                    color: searchHint,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Icon(
                      _isFocused ? Icons.search : Icons.search_outlined,
                      color: searchIcon,
                      size: _isFocused ? 26 : 24,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isFocused
                                ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                                : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () {
                                _searchController.clear();
                                _performSearch('');
                                _searchFocusNode.unfocus();
                              },
                              splashColor: colorScheme.primary.withOpacity(0.1),
                              highlightColor: colorScheme.primary.withOpacity(0.05),
                              child: Icon(
                                Icons.clear,
                                color: searchIcon,
                                size: 18,
                              ),
                            ),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  fillColor: searchBg,
                  filled: true,
                ),
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchFocusNode.requestFocus();
                  }
                },
                onChanged: (value) {
                  _performSearch(value);
                  setState(() {}); // Rebuild to update clear button visibility
                },
              ),
            ),
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off,
                          size: 40,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No results found',
                        style: TextStyle(
                          color: infoText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Try a different search term or check your spelling',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 15,
                          ),
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Lottie.asset(
                    'lib/assets/Search.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Search for people',
                  style: TextStyle(
                    color: infoText,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Find friends, family, or interesting profiles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 15,
                    ),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}