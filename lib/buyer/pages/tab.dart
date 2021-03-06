import 'package:flutter/material.dart';

const double _kTabHeight = 46.0;

class CustomTabBar extends StatefulWidget implements PreferredSizeWidget {
  CustomTabBar(
      {Key? key,
      required this.tabs,
      this.controller,
      this.duration = 250,
      this.backgroundColor,
      this.unselectedBackgroundColor,
      this.decoration,
      this.unselectedDecoration,
      this.labelStyle,
      this.unselectedLabelStyle,
      this.borderWidth = 0,
      this.borderColor = Colors.black,
      this.unselectedBorderColor = Colors.black,
      this.physics = const BouncingScrollPhysics(),
      this.contentPadding = const EdgeInsets.symmetric(horizontal: 4),
      this.buttonMargin = const EdgeInsets.all(4),
      this.labelSpacing = 4.0,
      this.radius = 7.0,
      this.height = _kTabHeight,
      this.center = false,
      this.onTap,
      this.tabDecoration,
      this.bottonwidthSize,
      this.bottonheightSize})
      : super(key: key) {
    assert(backgroundColor == null || decoration == null);
    assert(unselectedBackgroundColor == null || unselectedDecoration == null);
  }

  final List<Widget> tabs;
  final TabController? controller;
  final int duration;
  final Color? backgroundColor;
  final Color? unselectedBackgroundColor;
  final BoxDecoration? decoration;
  final BoxDecoration? unselectedDecoration;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final double borderWidth;
  final Color borderColor;
  final Color unselectedBorderColor;
  final ScrollPhysics physics;
  final EdgeInsets contentPadding;
  final EdgeInsets buttonMargin;
  final double labelSpacing;
  final double radius;
  final double? height;
  final bool center;
  final void Function(int)? onTap;
  final BoxDecoration? tabDecoration;
  final double? bottonwidthSize;
  final double? bottonheightSize;
  @override
  Size get preferredSize {
    return Size.fromHeight(height ??
        (_kTabHeight + contentPadding.vertical + buttonMargin.vertical));
  }

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with TickerProviderStateMixin {
  TabController? _controller;

  ScrollController _scrollController = new ScrollController();

  late AnimationController _animationController;

  late List<GlobalKey> _tabKeys;
  GlobalKey _tabsContainerKey = GlobalKey();
  GlobalKey _tabsParentKey = GlobalKey();

  int _currentIndex = 0;
  int _prevIndex = -1;
  int _aniIndex = 0;
  double _prevAniValue = 0;

  late bool _textLTR;

  EdgeInsets _centerPadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _getCenterPadding(context));

    _tabKeys = widget.tabs.map((Widget tab) => GlobalKey()).toList();

    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.duration));

    _animationController.value = 1.0;
    _animationController.addListener(() {
      setState(() {});
    });
  }

  void _updateTabController() {
    final TabController? newController =
        widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError('No TabController for ${widget.runtimeType}.\n'
            'When creating a ${widget.runtimeType}, you must either provide an explicit '
            'TabController using the "controller" property, or you must ensure that there '
            'is a DefaultTabController above the ${widget.runtimeType}.\n'
            'In this case, there was neither an explicit controller nor a default controller.');
      }
      return true;
    }());

    if (newController == _controller) return;

    if (_controllerIsValid) {
      _controller?.animation!.removeListener(_handleTabAnimation);
      _controller?.removeListener(_handleController);
    }
    _controller = newController;
    _controller?.animation!.addListener(_handleTabAnimation);
    _controller?.addListener(_handleController);
    _currentIndex = _controller!.index;
  }

  bool get _controllerIsValid => _controller?.animation != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
  }

  @override
  void didUpdateWidget(CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController();
    }

    if (widget.tabs.length > oldWidget.tabs.length) {
      final int delta = widget.tabs.length - oldWidget.tabs.length;
      _tabKeys.addAll(List<GlobalKey>.generate(delta, (int n) => GlobalKey()));
    } else if (widget.tabs.length < oldWidget.tabs.length) {
      _tabKeys.removeRange(widget.tabs.length, oldWidget.tabs.length);
    }
  }

  void _handleController() {
    if (_controller!.indexIsChanging) {
      _goToIndex(_controller!.index);
    }
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabAnimation);
      _controller!.removeListener(_handleController);
    }
    _controller = null;
    _scrollController.dispose();
    super.dispose();
  }

  _getCenterPadding(BuildContext context) {
    final RenderBox tabsParent =
        _tabsParentKey.currentContext!.findRenderObject() as RenderBox;
    final double screenWidth = tabsParent.size.width;

    RenderBox renderBox =
        _tabKeys.first.currentContext?.findRenderObject() as RenderBox;
    double size = renderBox.size.width;
    final double left = (screenWidth - size) / 2;

    renderBox = _tabKeys.last.currentContext?.findRenderObject() as RenderBox;
    size = renderBox.size.width;
    final double right = (screenWidth - size) / 2;
    _centerPadding = EdgeInsets.only(left: left, right: right);
  }

  Widget _buildButton(
    int index,
    Tab tab,
  ) {
    final double animationValue;
    if (index == _currentIndex)
      animationValue = _animationController.value;
    else if (index == _prevIndex)
      animationValue = 1 - _animationController.value;
    else
      animationValue = 0;

    final TextStyle? textStyle = TextStyle.lerp(
        widget.unselectedLabelStyle ?? TextStyle(color: Colors.black),
        widget.labelStyle ?? TextStyle(color: Colors.white),
        animationValue);
    final Color? borderColor = Color.lerp(
        widget.unselectedBorderColor, widget.borderColor, animationValue);
    final Color foregroundColor = textStyle?.color ?? Colors.black;

    final BoxDecoration? boxDecoration = BoxDecoration.lerp(
        widget.unselectedDecoration ??
            BoxDecoration(
                color: widget.unselectedBackgroundColor ?? Colors.grey[300]),
        widget.decoration ??
            BoxDecoration(
                color: widget.backgroundColor ??
                    Theme.of(context).colorScheme.secondary),
        animationValue);

    EdgeInsets buttonMargin = widget.buttonMargin;
    if (index == 0) {
    } else if (index == widget.tabs.length - 1) {}

    return Padding(
      key: _tabKeys[index],
      padding: buttonMargin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: boxDecoration,
              ),
            ),
            TextButton(
              onPressed: () {
                _controller?.animateTo(index);
                if (widget.onTap != null) widget.onTap!(index);
              },
              style: TextButton.styleFrom(
                minimumSize: Size.lerp(
                    Size(widget.bottonwidthSize ?? 50.0,
                        widget.bottonheightSize ?? 50.0),
                    Size(widget.bottonwidthSize ?? 50.0,
                        widget.bottonheightSize ?? 50.0),
                    10),
                padding: widget.contentPadding,
                textStyle: textStyle,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  side: (widget.borderWidth == 0)
                      ? BorderSide.none
                      : BorderSide(
                          color: borderColor ?? Colors.black,
                          width: widget.borderWidth,
                          style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
              child: Row(
                children: <Widget>[
                  tab.icon != null
                      ? IconTheme.merge(
                          data:
                              IconThemeData(size: 24.0, color: foregroundColor),
                          child: tab.icon!)
                      : Container(),
                  SizedBox(
                    width: tab.icon == null ||
                            (tab.text == null && tab.child == null)
                        ? 0
                        : widget.labelSpacing,
                  ),
                  tab.text != null
                      ? Text(
                          tab.text!,
                          style: textStyle,
                        )
                      : (tab.child ?? Container())
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    assert(() {
      if (_controller!.length != widget.tabs.length) {
        throw FlutterError(
            "Controller's length property (${_controller!.length}) does not match the "
            "number of tabs (${widget.tabs.length}) present in TabBar's tabs property.");
      }
      return true;
    }());
    if (_controller!.length == 0) return Container(height: widget.height);

    _textLTR = Directionality.of(context).index == 1;
    return Container(
      alignment: Alignment.center,
      width: screenSize.width,
      decoration: widget.tabDecoration,
      child: Opacity(
        opacity: (!widget.center || _centerPadding != EdgeInsets.zero) ? 1 : 0,
        child: AnimatedBuilder(
          animation: _animationController,
          key: _tabsParentKey,
          builder: (context, child) => SizedBox(
            key: _tabsContainerKey,
            height: widget.preferredSize.height,
            child: SingleChildScrollView(
              physics: widget.physics,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: widget.center ? _centerPadding : EdgeInsets.zero,
              child: Row(
                children: List.generate(
                  widget.tabs.length,
                  (int index) => _buildButton(index, widget.tabs[index] as Tab),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _handleTabAnimation() {
    _aniIndex = ((_controller!.animation!.value > _prevAniValue)
            ? _controller!.animation!.value
            : _prevAniValue)
        .round();
    if (!_controller!.indexIsChanging && _aniIndex != _currentIndex) {
      _setCurrentIndex(_aniIndex);
    }
    _prevAniValue = _controller!.animation!.value;
  }

  _goToIndex(int index) {
    if (index != _currentIndex) {
      _setCurrentIndex(index);
      _controller?.animateTo(index);
    }
  }

  _setCurrentIndex(int index) {
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
    _scrollTo(index);
    _triggerAnimation();
  }

  _triggerAnimation() {
    _animationController.reset();

    _animationController.forward();
  }

  _scrollTo(int index) {
    final RenderBox tabsContainer =
        _tabsContainerKey.currentContext!.findRenderObject() as RenderBox;
    double screenWidth = tabsContainer.size.width;
    final tabsContainerPosition = tabsContainer.localToGlobal(Offset.zero).dx;

    final tabsContainerOffset = Offset(-tabsContainerPosition, 0);

    RenderBox renderBox =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox;

    double size = renderBox.size.width;

    double position = renderBox.localToGlobal(tabsContainerOffset).dx;

    double offset = (position + size / 2) - screenWidth / 2;

    if (offset < 0) {
      renderBox = (_textLTR ? _tabKeys.first : _tabKeys.last)
          .currentContext
          ?.findRenderObject() as RenderBox;

      position = renderBox.localToGlobal(tabsContainerOffset).dx;

      if (!widget.center && position > offset) offset = position;
    } else {
      renderBox = (_textLTR ? _tabKeys.last : _tabKeys.first)
          .currentContext
          ?.findRenderObject() as RenderBox;

      position = renderBox.localToGlobal(tabsContainerOffset).dx;

      size = renderBox.size.width;

      if (position + size < screenWidth) screenWidth = position + size;

      if (!widget.center && position + size - offset < screenWidth)
        offset = position + size - screenWidth;
    }
    offset *= (_textLTR ? 1 : -1);

    _scrollController.animateTo(offset + _scrollController.offset,
        duration: new Duration(milliseconds: widget.duration),
        curve: Curves.easeInOut);
  }
}
