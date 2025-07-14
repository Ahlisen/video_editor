import 'package:flutter/material.dart';
import 'package:video_editor/src/widgets/trim/indicator_or_scroll_gesture_recognizer.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/widgets/trim/thumbnail_slider.dart';

class RegularSlider extends StatefulWidget {
  const RegularSlider({
    super.key,
    required this.controller,
    this.height = 60,
  });

  final VideoEditorController controller;
  final double height;

  @override
  State<RegularSlider> createState() => _RegularSliderState();
}

class _RegularSliderState extends State<RegularSlider> {
  bool _indicatorDragActive = false;
  double _indicatorPosition = 0.0;
  Size _sliderLayout = Size.zero;
  Size _fullLayout = Size.zero;
  late final double _maxViewportRatio;
  late final double _viewportRatio;
  late final bool _isExtendSlider;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _indicatorPosition = widget.controller.trimPosition;
    _maxViewportRatio = 2.5;
    _viewportRatio = (_maxViewportRatio).clamp(
      1.0,
      widget.controller.videoDuration.inMilliseconds /
          widget.controller.maxDuration.inMilliseconds,
    );
    _isExtendSlider = _viewportRatio > 1;
    _scrollController = ScrollController();
    widget.controller.addListener(_syncIndicator);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncIndicator() {
    setState(() {
      _indicatorPosition = widget.controller.trimPosition;
    });
  }

  Offset? _dragStart;

  void _onPanStart(DragStartDetails details) {
    // Activate indicator drag so scroll view disables scrolling
    setState(() {
      _indicatorDragActive = true;
    });
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // print('[RegularSlider] onPanUpdate: ${details.localPosition}');
    // Calculate thumbnail width similar to ThumbnailSlider
    final double thumbnailWidth = widget.height *
        (widget.controller.video.value.aspectRatio == 0
            ? 1.0
            : widget.controller.video.value.aspectRatio);

    // Only handle indicator drag if called from IndicatorOrScrollGestureRecognizer
    // if (_dragStart != null) {
    double localDx = details.localPosition.dx -
        (widget.height *
                (widget.controller.video.value.aspectRatio == 0
                    ? 1.0
                    : widget.controller.video.value.aspectRatio)) /
            2;
    if (_isExtendSlider) {
      localDx += _scrollController.offset;
      localDx = localDx.clamp(0.0, _fullLayout.width);
    } else {
      localDx = localDx.clamp(0.0, _sliderLayout.width);
    }
    final positionRatio =
        localDx / (_fullLayout.width == 0 ? 1 : _fullLayout.width);
    print('[RegularSlider] onPanUpdate: ${details.localPosition}');
    setState(() {
      _indicatorPosition = positionRatio;
    });
    final duration = widget.controller.videoDuration * positionRatio;
    widget.controller.video.seekTo(duration);
    // } else if (_isExtendSlider) {
    //   // Scroll the SingleChildScrollView with momentum
    //   final delta = details.delta.dx;
    //   final target = (_scrollController.offset - delta)
    //       .clamp(0.0, _fullLayout.width - _sliderLayout.width);
    //   _scrollController.animateTo(
    //     target,
    //     duration: const Duration(milliseconds: 100),
    //     curve: Curves.decelerate,
    //   );
    // }
  }

  void _onPanEnd(DragEndDetails details) {
    // Deactivate indicator drag so scroll view enables scrolling
    setState(() {
      _indicatorDragActive = false;
    });
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double horizontalMargin = 0.0;
        final double height = widget.height;
        final Size sliderLayout = Size(
            constraints.maxWidth - horizontalMargin * 2, constraints.maxHeight);
        _sliderLayout = sliderLayout;
        _fullLayout = Size(
          sliderLayout.width * (_isExtendSlider ? _viewportRatio : 1),
          constraints.maxHeight,
        );

        // Calculate thumbnail width similar to ThumbnailSlider
        final double thumbnailWidth = height *
            (widget.controller.video.value.aspectRatio == 0
                ? 1.0
                : widget.controller.video.value.aspectRatio);

        Widget sliderContent = Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: _fullLayout.width,
              height: _fullLayout.height,
              color: Colors.grey.shade300,
            ),
            ThumbnailSlider(
              controller: widget.controller,
              height: height,
            ),
            Positioned(
              left: _indicatorPosition * _fullLayout.width,
              top: 0,
              child: Container(
                width: thumbnailWidth,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );

        Widget scrollableContent = sliderContent;
        if (_isExtendSlider) {
          scrollableContent = SizedBox(
            width: _fullLayout.width,
            height: _fullLayout.height,
            child: sliderContent,
          );
        }

        return SizedBox(
          width: sliderLayout.width,
          height: _fullLayout.height,
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              IndicatorOrScrollGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      IndicatorOrScrollGestureRecognizer>(
                () => IndicatorOrScrollGestureRecognizer(
                  indicatorX: _indicatorPosition * _fullLayout.width,
                  onIndicatorPanStart: _onPanStart,
                  onIndicatorPanUpdate: _onPanUpdate,
                  onIndicatorPanEnd: _onPanEnd,
                ),
                (instance) {},
              ),
            },
            child: _isExtendSlider
                ? SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: _indicatorDragActive
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    child: scrollableContent,
                  )
                : scrollableContent,
          ),
        );
      },
    );
  }
}
