import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

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

    // Linearly interpolate so indicator can reach all durations
    final double sliderWidth = _sliderLayout.width;
    double localDx = details.localPosition.dx;
    // Map localDx in [0, sliderWidth] to positionRatio in [0, 1]
    double positionRatio =
        ((localDx - (thumbnailWidth / 2)) / (sliderWidth - thumbnailWidth))
            .clamp(0.0, 1.0);
    print('Position ratio: $positionRatio');
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

        // Get TrimSliderStyle from controller
        final TrimSliderStyle style = widget.controller.trimStyle;
        return ClipRRect(
          borderRadius: BorderRadius.circular(style.borderRadius),
          child: SizedBox(
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
                    left: _indicatorPosition *
                        (_sliderLayout.width - thumbnailWidth),
                    top: 0,
                    child: Container(
                      width: thumbnailWidth,
                      height: height,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: style.positionLineColor,
                            width: style.lineWidth),
                        borderRadius: BorderRadius.circular(style.borderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
