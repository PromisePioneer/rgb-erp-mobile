import 'package:flutter/material.dart';

/// Base layout that wraps content with proper SafeArea and bottom padding
/// for the app's bottom navigation bar.
///
/// Usage (like Laravel's @section('content')):
/// ```dart
/// class MyScreen extends AppContent {
///   const MyScreen({super.key});
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return Center(child: Text('Hello'));
///   }
/// }
/// ```
abstract class AppContent extends StatelessWidget {
  const AppContent({super.key});

  /// The actual content of the screen - override this like Laravel's @section('content')
  Widget buildContent(BuildContext context);

  /// Optional: App bar configuration. Return null for no app bar.
  AppBar? buildAppBar(BuildContext context) => null;

  /// Optional: FAB configuration. Return null for no FAB.
  Widget? buildFloatingActionButton(BuildContext context) => null;

  /// Optional: FAB positioning. Default handles bottom nav spacing.
  EdgeInsets getFloatingActionButtonPadding(BuildContext context) =>
      EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom);

  /// Optional: Bottom bar (for forms, etc.)
  Widget? buildBottomBar(BuildContext context) => null;

  /// Optional: Background color
  Color? get backgroundColor => null;

  /// Optional: Extend body behind app bar (for transparent app bar)
  bool get extendBodyBehindAppBar => false;

  /// Whether to wrap body in SafeArea (default: true)
  bool get useSafeArea => true;

  /// Bottom nav bar height
  static const double bottomNavHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: useSafeArea
          ? SafeArea(
              bottom: false, // Don't add bottom safe area, we handle it manually
              child: _buildBody(context),
            )
          : _buildBody(context),
      floatingActionButton: buildFloatingActionButton(context) != null
          ? Padding(
              padding: getFloatingActionButtonPadding(context),
              child: buildFloatingActionButton(context),
            )
          : null,
      bottomNavigationBar: buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        Expanded(child: buildContent(context)),
        // Bottom padding to account for bottom nav bar
        SizedBox(height: bottomNavHeight + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

/// Mixin for screens that need to refresh data
mixin RefreshableContent<T extends StatefulWidget> on State<T> {
  /// Override to provide refresh callback
  Future<void> onRefresh();

  /// Wrap your body with this for pull-to-refresh
  Widget buildRefreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Screen wrapper for screens without AppBar
class AppScaffold extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: child,
      ),
    );
  }
}

/// Screen wrapper for screens with AppBar and content
class AppScreen extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const AppScreen({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.bottom,
  });

  static const double bottomNavHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        centerTitle: centerTitle,
        actions: actions,
        leading: leading,
        bottom: bottom,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: body),
            // Bottom padding for nav bar
            SizedBox(height: bottomNavHeight + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton != null
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: floatingActionButton,
            )
          : null,
    );
  }
}

/// Screen wrapper for screens with TabBar
class AppTabScreen extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final TabBar? tabBar;
  final TabController? tabController;
  final List<Widget> tabViews;
  final Widget? floatingActionButton;

  const AppTabScreen({
    super.key,
    required this.title,
    this.actions,
    this.tabBar,
    this.tabController,
    required this.tabViews,
    this.floatingActionButton,
  });

  static const double bottomNavHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: actions,
        bottom: tabBar,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: tabViews,
              ),
            ),
            // Bottom padding for nav bar
            SizedBox(height: bottomNavHeight + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton != null
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: floatingActionButton,
            )
          : null,
    );
  }
}
