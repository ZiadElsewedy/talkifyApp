import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final String? helperText;
  final String? errorText;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const AnimatedTextField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.label,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.helperText,
    this.errorText,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> 
    with TickerProviderStateMixin {
  
  late AnimationController _focusAnimationController;
  late AnimationController _shakeAnimationController;
  late AnimationController _errorAnimationController;
  
  late Animation<double> _focusAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shakeAnimation;
  late Animation<double> _errorFadeAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;
  bool _hasError = false;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
    _checkInitialState();
  }

  void _initializeAnimations() {
    // Focus animation controller
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    // Shake animation for errors
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Error fade animation
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define animations
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOutBack,
    ));

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.elasticIn,
    ));

    _errorFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupListeners() {
    widget.focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _checkInitialState() {
    _isFocused = widget.focusNode.hasFocus;
    _hasText = widget.controller.text.isNotEmpty;
    
    if (_isFocused) {
      _focusAnimationController.forward();
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    
    final wasFocused = _isFocused;
    _isFocused = widget.focusNode.hasFocus;
    
    if (_isFocused != wasFocused) {
      setState(() {});
      
      if (_isFocused) {
        _focusAnimationController.forward();
        _clearError();
      } else {
        _focusAnimationController.reverse();
        _validateField();
      }
    }
  }

  void _handleTextChange() {
    if (!mounted) return;
    
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_hasError && hasText) {
        _clearError();
      }
    }
    
    widget.onChanged?.call(widget.controller.text);
  }

  void _validateField() {
    if (widget.validator == null) return;
    
    final error = widget.validator!(widget.controller.text);
    if (error != null && error != _currentError) {
      _showError(error);
    }
  }

  void _showError(String error) {
    setState(() {
      _hasError = true;
      _currentError = error;
    });
    
    _errorAnimationController.forward();
    _shakeAnimationController.forward().then((_) {
      _shakeAnimationController.reverse();
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _currentError = null;
      });
      _errorAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _shakeAnimationController.dispose();
    _errorAnimationController.dispose();
    
    widget.focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label (optional)
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        
        // Main text field
        SlideTransition(
          position: _shakeAnimation,
          child: AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBorderColor(),
                      width: _getBorderWidth(),
                    ),
                    boxShadow: _getBoxShadow(),
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    inputFormatters: widget.inputFormatters,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    onFieldSubmitted: widget.onFieldSubmitted,
                    style: TextStyle(
                      color: widget.enabled ? Colors.white : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: _buildPrefixIcon(),
                      suffixIcon: _buildSuffixIcon(),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: 18,
                      ),
                      counterText: '', // Hide character counter
                      errorStyle: const TextStyle(height: 0), // Hide default error
                    ),
                    validator: widget.validator,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Error message
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _hasError ? 24 : 0,
          child: FadeTransition(
            opacity: _errorFadeAnimation,
            child: _hasError ? _buildErrorMessage() : const SizedBox.shrink(),
          ),
        ),
        
        // Helper text
        if (widget.helperText != null && !_hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrefixIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Icon(
        widget.icon,
        color: _getIconColor(),
        size: _getIconSize(),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (!widget.isPassword) return const SizedBox.shrink();
    
    return IconButton(
      onPressed: widget.enabled ? widget.onToggleVisibility : null,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: child,
          );
        },
        child: Icon(
          widget.obscureText 
              ? Icons.visibility_outlined 
              : Icons.visibility_off_outlined,
          key: ValueKey(widget.obscureText),
          color: _getIconColor(),
          size: 22,
        ),
      ),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[400],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _currentError ?? '',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for styling
  Color _getBackgroundColor() {
    if (!widget.enabled) {
      return Colors.white.withOpacity(0.03);
    }
    if (_hasError) {
      return Colors.red.withOpacity(0.08);
    }
    if (_isFocused) {
      return Colors.white.withOpacity(0.12);
    }
    return Colors.white.withOpacity(0.06);
  }

  Color _getBorderColor() {
    if (!widget.enabled) {
      return Colors.grey.withOpacity(0.2);
    }
    if (_hasError) {
      return Colors.red.withOpacity(0.6);
    }
    if (_isFocused) {
      return Colors.white.withOpacity(0.4);
    }
    return Colors.white.withOpacity(0.15);
  }

  double _getBorderWidth() {
    if (_hasError || _isFocused) {
      return 2.0;
    }
    return 1.0;
  }

  List<BoxShadow> _getBoxShadow() {
    if (!widget.enabled) return [];
    
    if (_hasError) {
      return [
        BoxShadow(
          color: Colors.red.withOpacity(0.2),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
    }
    
    if (_isFocused) {
      return [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  Color _getIconColor() {
    if (!widget.enabled) {
      return Colors.grey[600]!;
    }
    if (_hasError) {
      return Colors.red[400]!;
    }
    if (_isFocused) {
      return Colors.white;
    }
    return Colors.grey[400]!;
  }

  double _getIconSize() {
    return _isFocused ? 24.0 : 22.0;
  }
}