import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class DescriptionTextField extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;

  const DescriptionTextField({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  @override
  State<DescriptionTextField> createState() => _DescriptionTextFieldState();
}

class _DescriptionTextFieldState extends State<DescriptionTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
        
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);

    // Initial check in case the controller already has text
    if (widget.controller.text.isNotEmpty) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
    if (_focusNode.hasFocus || widget.controller.text.isNotEmpty) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {}); // To rebuild and update character count
    }
    if (widget.controller.text.isNotEmpty) {
      _animationController.forward();
    } else if (!_focusNode.hasFocus) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF5BA3F5).withOpacity(0.5),
                      blurRadius: 8.0,
                      spreadRadius: 1.0,
                    ),
                  ]
                : [],
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF5BA3F5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                maxLines: 5,
                maxLength: widget.maxLength,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(16, 34, 16, 16),
                  border: InputBorder.none,
                  counterText: '',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.maxLength),
                ],
              ),
              PositionedTransition(
                rect: RelativeRectTween(
                  begin: RelativeRect.fromLTRB(16, 34, 16, 0),
                  end: RelativeRect.fromLTRB(16, 8, 16, 0),
                ).animate(_animationController),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.85)
                      .animate(_animationController),
                  alignment: Alignment.topLeft,
                  child: IgnorePointer(
                    child: Text(
                      '/ Describe your perfect hotspot',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            '${widget.controller.text.length} / ${widget.maxLength}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
      ],
    );
  }
}