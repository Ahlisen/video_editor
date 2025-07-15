import 'package:flutter/material.dart';
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
  double _indicatorPosition = 0.0;
  Size _sliderLayout = Size.zero;

  @override
  void initState() {
    super.initState();
    _indicatorPosition = widget.controller.trimPosition;
    // Removed scroll-related initialization
    widget.controller.addListener(_syncIndicator);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncIndicator);
    // Removed scroll controller dispose
    super.dispose();
  }

  void _syncIndicator() {
    setState(() {
      _indicatorPosition = widget.controller.trimPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Calculate thumbnail width similar to ThumbnailSlider
    final double thumbnailWidth = widget.height *
        (widget.controller.video.value.aspectRatio == 0
            ? 1.0
            : widget.controller.video.value.aspectRatio);

    double localDx = details.localPosition.dx - (thumbnailWidth / 2);
    localDx = localDx.clamp(0.0, _sliderLayout.width);
    final positionRatio =
        localDx / (_sliderLayout.width == 0 ? 1 : _sliderLayout.width);
    setState(() {
      _indicatorPosition = positionRatio;
    });
    final duration = widget.controller.videoDuration * positionRatio;
    widget.controller.video.seekTo(duration);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double horizontalMargin = 0.0;
        final double height = widget.height;
        final Size sliderLayout = Size(
            constraints.maxWidth - horizontalMargin * 2, constraints.maxHeight);
        _sliderLayout = sliderLayout;

        // Calculate thumbnail width similar to ThumbnailSlider
        final double thumbnailWidth = height *
            (widget.controller.video.value.aspectRatio == 0
                ? 1.0
                : widget.controller.video.value.aspectRatio);

        return SizedBox(
          width: sliderLayout.width,
          height: sliderLayout.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _onPanUpdate,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                ThumbnailSlider(
                  controller: widget.controller,
                  height: height,
                ),
                Positioned(
                  left: _indicatorPosition * _sliderLayout.width,
                  top: 0,
                  child: Container(
                    width: thumbnailWidth,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
