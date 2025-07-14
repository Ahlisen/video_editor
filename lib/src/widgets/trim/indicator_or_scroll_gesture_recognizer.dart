import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom gesture recognizer to distinguish indicator drag from scroll drag
class IndicatorOrScrollGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  final double indicatorX;
  final double indicatorTouchRadius;
  final void Function(DragStartDetails)? onIndicatorPanStart;
  final void Function(DragUpdateDetails)? onIndicatorPanUpdate;
  final void Function(DragEndDetails)? onIndicatorPanEnd;
  bool _isIndicatorDrag = false;

  IndicatorOrScrollGestureRecognizer({
    required this.indicatorX,
    this.indicatorTouchRadius = 24.0,
    this.onIndicatorPanStart,
    this.onIndicatorPanUpdate,
    this.onIndicatorPanEnd,
    Object? debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void addPointer(PointerDownEvent event) {
    // Always add pointer, but decide in accept/reject logic
    super.addPointer(event);
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    // Always allow pointer, but decide in accept/reject logic
    return true;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      print(
          'Local position dx: ${event.localPosition.dx} (indicatorX: $indicatorX) ');
      if ((event.localPosition.dx - indicatorX).abs() < indicatorTouchRadius) {
        _isIndicatorDrag = true;
        print('[IndicatorOrScrollGestureRecognizer] Indicator drag started');
        resolve(GestureDisposition.accepted);
        didStartDrag();
      } else {
        _isIndicatorDrag = false;
        print('[IndicatorOrScrollGestureRecognizer] Scroll drag started');
        resolve(GestureDisposition.rejected);
      }
    }
    if (_isIndicatorDrag) {
      if (event is PointerMoveEvent) {
        didUpdateDrag(DragUpdateDetails(globalPosition: event.position));
      } else if (event is PointerUpEvent) {
        didEndDrag(DragEndDetails());
      }
      super.handleEvent(event);
    } else if (event is PointerMoveEvent || event is PointerUpEvent) {
      // Prevent scroll view from handling move/up events if not indicator drag
      return;
    }
  }

  // Remove @override, these are not overrides but custom hooks
  void didStartDrag() {
    if (_isIndicatorDrag && onIndicatorPanStart != null) {
      print('[IndicatorOrScrollGestureRecognizer] didStartDrag');
      onIndicatorPanStart!(
          DragStartDetails(globalPosition: Offset(indicatorX, 0)));
    }
  }

  void didUpdateDrag(DragUpdateDetails details) {
    if (_isIndicatorDrag && onIndicatorPanUpdate != null) {
      print('[IndicatorOrScrollGestureRecognizer] didUpdateDrag');
      onIndicatorPanUpdate!(details);
    }
  }

  void didEndDrag(DragEndDetails details) {
    if (_isIndicatorDrag && onIndicatorPanEnd != null) {
      print('[IndicatorOrScrollGestureRecognizer] didEndDrag');
      onIndicatorPanEnd!(details);
    }
  }
}
