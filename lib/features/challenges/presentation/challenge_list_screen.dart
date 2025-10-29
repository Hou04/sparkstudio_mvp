/// 📚 Futuristic Challenge List Screen
/// 
/// Professional challenge browsing interface with advanced filtering,
/// search capabilities, and immersive animations.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../logic/challenge_controller.dart';
import '../data/challenge_model.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChallengeType _selectedFilter = ChallengeType.mixed;
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ChallengeController>();
      if (controller.challenges.isEmpty) {
        controller.initialize();
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 
          _scrollController.position.maxScrollExtent) {
        _loadMoreChallenges();
      }
    });
  }

  void _loadMoreChallenges() {
    final controller = context.read<ChallengeController>();
    // Implement pagination if needed
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(ChallengeType filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _navigateToChallengeDetail(ChallengeModel challenge) {
    Navigator.pushNamed(
      context,
      '/challenges/detail',
      arguments: challenge.id,
    );
  }

  void _navigateToStudio(ChallengeModel challenge) {
    Navigator.pushNamed(
      context,
      '/creative/studio',
      arguments: challenge,
    );
  }

  List<ChallengeModel> _getFilteredChallenges(List<ChallengeModel> challenges) {
    var filtered = challenges;

    // Apply type filter
    if (_selectedFilter != ChallengeType.mixed) {
      filtered = filtered.where((c) => c.type == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) => 
        c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: _slideAnimation.value,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ChallengeController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.challenges.isEmpty) {
          return const Center(
            child: LoadingIndicator(
              message: 'Loading creative challenges...',
            ),
          );
        }

        if (controller.hasError) {
          return _buildErrorState(controller.error!);
        }

        final filteredChallenges = _getFilteredChallenges(controller.challenges);

        return Column(
          children: [
            // Header Section
            _buildHeaderSection(controller),
            
            // Filter and Search Section
            _buildFilterSection(),
            
            // Challenges List
            Expanded(
              child: _buildChallengesList(filteredChallenges, controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderSection(ChallengeController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Search
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creative Challenges',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Discover daily creative prompts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: IconButton(
                  onPressed: _toggleSearch,
                  icon: Icon(
                    _showSearch ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          if (_showSearch) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search challenges...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.clear, color: Colors.white),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ChallengeType.values.map((type) {
            final isSelected = _selectedFilter == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(type),
                label: Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.primary.withOpacity(0.3),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChallengesList(List<ChallengeModel> challenges, ChallengeController controller) {
    if (challenges.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        color: Colors.white,
        backgroundColor: AppColors.primary,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildChallengeCard(challenge, index);
          },
        ),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToChallengeDetail(challenge),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spaceL),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _getTypeGradient(challenge.type),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Text(
                        challenge.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (challenge.isTrending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  challenge.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Stats and Actions
                Row(
                  children: [
                    // Stats
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.people_outline,
                          '${challenge.participantCount}',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.article_outlined,
                          '${challenge.submissionCount}',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.auto_awesome,
                          challenge.difficultyLabel,
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Action Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: IconButton(
                        onPressed: () => _navigateToStudio(challenge),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Challenges Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new creative challenges!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedFilter != ChallengeType.mixed)
              CustomButton(
                label: 'Clear Filters',
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = ChallengeType.mixed;
                    _searchController.clear();
                  });
                },
                gradient: AppColors.secondaryGradient,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<ChallengeController>(
              builder: (context, controller, child) {
                return CustomButton(
                  label: 'Try Again',
                  onPressed: controller.initialize,
                  gradient: AppColors.primaryGradient,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Gradient _getTypeGradient(ChallengeType type) {
    switch (type) {
      case ChallengeType.photo:
        return const LinearGradient(
          colors: [Color(0xFFEC407A), Color(0xFFAB47BC)],
        );
      case ChallengeType.text:
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF478ED1)],
        );
      case ChallengeType.video:
        return const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
        );
      case ChallengeType.audio:
        return const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF66BB6A)],
        );
      case ChallengeType.mixed:
        return const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFFA726)],
        );
    }
  }
}