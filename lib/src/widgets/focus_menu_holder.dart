import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focused_menu/src/models/focused_menu_item.dart';
import 'package:focused_menu/src/widgets/focused_menu_datails.dart';

class FocusedMenuHolderController {
  late _FocusedMenuHolderState _widgetState;
  bool _isOpened = false;

  void _addState(_FocusedMenuHolderState widgetState) {
    this._widgetState = widgetState;
  }

  void open() {
    if (_widgetState.mounted) {
      _widgetState.openMenu();
      _isOpened = true;
    }
  }

  void close() {
    if (_isOpened && _widgetState.mounted) {
      Navigator.pop(_widgetState.savedContext);
      _isOpened = false;
    }
  }
}

class FocusedMenuHolder extends StatefulWidget {
  final Widget child;
  final double? menuItemExtent;
  final double? menuWidth;
  final List<FocusedMenuItem> menuItems;
  final bool? animateMenuItems;
  final BoxDecoration? menuBoxDecoration;
  final Function? onPressed;
  final Duration? duration;
  final double? blurSize;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;

  /// Actions to be shown in the toolbar.
  final List<Widget>? toolbarActions;

  /// Enable scroll in menu. Default is true.
  final bool enableMenuScroll;

  /// Open with tap instead of long press.
  final bool openWithTap;
  final FocusedMenuHolderController? controller;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  final Duration? pressDuration;

  const FocusedMenuHolder({
    Key? key,
    required this.child,
    required this.menuItems,
    this.onPressed,
    this.duration,
    this.menuBoxDecoration,
    this.menuItemExtent,
    this.animateMenuItems,
    this.blurSize,
    this.blurBackgroundColor,
    this.menuWidth,
    this.bottomOffsetHeight,
    this.menuOffset,
    this.toolbarActions,
    this.enableMenuScroll = true,
    this.openWithTap = false,
    this.controller,
    this.onOpened,
    this.onClosed,
    this.pressDuration,
  }) : super(key: key);

  @override
  _FocusedMenuHolderState createState() => _FocusedMenuHolderState(controller);
}

class _FocusedMenuHolderState extends State<FocusedMenuHolder> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = Offset(0, 0);
  Size? childSize;
  Timer? _pressTimer;
  late BuildContext savedContext;

  _FocusedMenuHolderState(FocusedMenuHolderController? _controller) {
    if (_controller != null) {
      _controller._addState(this);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getOffset();
    });
  }

  void _getOffset() {
    if (containerKey.currentContext != null) {
      RenderBox renderBox =
          containerKey.currentContext!.findRenderObject() as RenderBox;
      Size size = renderBox.size;
      Offset offset = renderBox.localToGlobal(Offset.zero);
      if (mounted) {
        setState(() {
          this.childOffset = Offset(offset.dx, offset.dy);
          childSize = size;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: containerKey,
      onPointerDown: (PointerDownEvent event) {
        savedContext = context;
        _getOffset();
        widget.onPressed?.call();
        if (widget.openWithTap) {
          _pressTimer?.cancel();
          openMenu();
        } else {
          _pressTimer = Timer(
              widget.pressDuration ?? Duration(milliseconds: 500), () async {
            await openMenu();
          });
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        _pressTimer?.cancel();
      },
      onPointerUp: (PointerUpEvent event) {
        _pressTimer?.cancel();
      },
      child: widget.child,
    );
  }

  Future<void> openMenu() async {
    widget.onOpened?.call();

    await Navigator.push(
      savedContext,
      PageRouteBuilder(
        transitionDuration: widget.duration ?? Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: FocusedMenuDetails(
              itemExtent: widget.menuItemExtent,
              menuBoxDecoration: widget.menuBoxDecoration,
              child: widget.child,
              childOffset: childOffset,
              childSize: childSize,
              menuItems: widget.menuItems,
              blurSize: widget.blurSize,
              menuWidth: widget.menuWidth,
              blurBackgroundColor: widget.blurBackgroundColor,
              animateMenu: widget.animateMenuItems ?? true,
              bottomOffsetHeight: widget.bottomOffsetHeight ?? 0,
              menuOffset: widget.menuOffset ?? 0,
              toolbarActions: widget.toolbarActions,
              enableMenuScroll: widget.enableMenuScroll,
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    ).whenComplete(() => widget.onClosed?.call());
  }
}
