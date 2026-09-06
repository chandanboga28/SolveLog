import 'package:flutter/material.dart';

class PlatformCard extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isAddButton;

  const PlatformCard({
    Key? key,
    required this.icon,
    required this.name,
    required this.onTap,
    this.onLongPress,
    this.isAddButton = false,
  }) : super(key: key);

  @override
  State<PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<PlatformCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180,
          height: 140,
          decoration: BoxDecoration(
            color: widget.isAddButton
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF1A1A1A),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.03),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Text(
                      widget.icon,
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}