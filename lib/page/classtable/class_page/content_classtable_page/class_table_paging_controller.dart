// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

part of '../content_classtable_page.dart';

class ClassTablePagingController extends ChangeNotifier {
  final bool Function() isMounted;

  ClassTablePagingController({required this.isMounted});

  late PageController pageController;
  late ScrollController rowController;
  Listenable? _weekListenable;
  late int Function() _selectedWeek;
  late int Function() _semesterLength;
  late ValueChanged<int> _onWeekSelected;
  double? _viewportWidth;
  int? _lastAnimatedWeek;
  int _animationToken = 0;
  bool _ignoreContentPageChanges = false;
  bool _skipNextContentPageAnimation = false;
  bool _hasControllers = false;
  bool isTopRowLocked = false;

  void bind({
    required Listenable weekListenable,
    required int Function() selectedWeek,
    required int Function() semesterLength,
    required ValueChanged<int> onWeekSelected,
    required double viewportWidth,
  }) {
    final listenerChanged = _weekListenable != weekListenable;
    if (listenerChanged) {
      _weekListenable?.removeListener(_switchPage);
      _weekListenable = weekListenable;
      _weekListenable!.addListener(_switchPage);
    }
    _selectedWeek = selectedWeek;
    _semesterLength = semesterLength;
    _onWeekSelected = onWeekSelected;

    if (!listenerChanged &&
        _hasControllers &&
        _viewportWidth == viewportWidth) {
      return;
    }

    if (_hasControllers) {
      pageController.dispose();
      rowController.dispose();
    }

    pageController = PageController(
      initialPage: _selectedWeek(),
      keepPage: true,
    );
    _viewportWidth = viewportWidth;
    rowController = ScrollController(
      initialScrollOffset: _weekScrollOffset(_selectedWeek()),
      keepScrollOffset: true,
    );
    _lastAnimatedWeek = _selectedWeek();
    _animationToken++;
    _setTopRowLocked(false);
    _hasControllers = true;
  }

  @override
  void dispose() {
    _weekListenable?.removeListener(_switchPage);
    if (_hasControllers) {
      pageController.dispose();
      rowController.dispose();
    }
    super.dispose();
  }

  double _weekScrollOffset(int week) {
    final viewportWidth = _viewportWidth;
    if (viewportWidth == null) {
      return 0;
    }

    final itemWidth = weekButtonWidth + 2 * weekButtonHorizontalPadding;
    final rawOffset = week * itemWidth - (viewportWidth - itemWidth) / 2;
    final maxOffset = _semesterLength() * itemWidth - viewportWidth;
    return rawOffset.clamp(0.0, maxOffset > 0 ? maxOffset : 0.0).toDouble();
  }

  void chooseWeek(int index) {
    if (_selectedWeek() == index) {
      return;
    }
    _onWeekSelected(index);
  }

  void chooseWeekAt(double viewportX) {
    if (!rowController.hasClients) {
      return;
    }

    final itemWidth = weekButtonWidth + 2 * weekButtonHorizontalPadding;
    final index = ((rowController.position.pixels + viewportX) / itemWidth)
        .floor()
        .clamp(0, _semesterLength() - 1);
    chooseWeek(index);
  }

  void onPageChanged(int value) {
    if (_ignoreContentPageChanges || _selectedWeek() == value) {
      return;
    }
    _skipNextContentPageAnimation = true;
    _onWeekSelected(value);
  }

  void _setTopRowLocked(bool value) {
    if (isTopRowLocked == value) {
      return;
    }
    isTopRowLocked = value;
    notifyListeners();
  }

  void _switchPage() {
    if (!isMounted() || !_hasControllers) {
      return;
    }
    final targetWeek = _selectedWeek();
    if (_lastAnimatedWeek == targetWeek) {
      return;
    }
    if (!rowController.hasClients || !pageController.hasClients) {
      _setTopRowLocked(false);
      return;
    }

    _lastAnimatedWeek = targetWeek;
    final animationToken = ++_animationToken;
    final skipContentPageAnimation = _skipNextContentPageAnimation;
    _skipNextContentPageAnimation = false;
    _setTopRowLocked(true);
    notifyListeners();

    final animations = <Future<void>>[
      rowController.animateTo(
        _weekScrollOffset(targetWeek),
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: changePageTime),
      ),
    ];

    final contentPage = pageController.page;
    Future<void>? contentPageAnimation;
    if (!skipContentPageAnimation &&
        (contentPage == null || (contentPage - targetWeek).abs() > 0.01)) {
      _ignoreContentPageChanges = true;
      contentPageAnimation = pageController.animateToPage(
        targetWeek,
        curve: Curves.easeInOutCubic,
        duration: const Duration(milliseconds: changePageTime),
      );
      animations.add(contentPageAnimation);
    }

    contentPageAnimation?.whenComplete(() {
      if (isMounted() && animationToken == _animationToken) {
        _ignoreContentPageChanges = false;
      }
    });

    Future.wait(animations).whenComplete(() {
      if (isMounted() && animationToken == _animationToken) {
        _ignoreContentPageChanges = false;
        _setTopRowLocked(false);
      }
    });
  }
}
