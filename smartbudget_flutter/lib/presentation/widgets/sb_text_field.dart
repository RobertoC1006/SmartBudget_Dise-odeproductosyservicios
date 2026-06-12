import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class SBTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool isCurrency;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const SBTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.isCurrency = false,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  factory SBTextField.email({
    Key? key,
    TextEditingController? controller,
    String? labelText = 'Correo electrónico',
    String? hintText = 'correo@ejemplo.com',
    Widget? prefixIcon = const Icon(Icons.email_outlined, color: AppColors.textSecondary),
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return SBTextField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu correo';
        }
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(value)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    );
  }

  factory SBTextField.password({
    Key? key,
    TextEditingController? controller,
    String? labelText = 'Contraseña',
    String? hintText = '••••••••',
    Widget? prefixIcon = const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return _SBPasswordField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      onChanged: onChanged,
      validator: validator,
    );
  }

  factory SBTextField.currency({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? labelText = 'Monto',
    String? hintText = '0.00',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return SBTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      hintText: hintText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      isCurrency: true,
      prefixIcon: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Text(
          'S/',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
      onChanged: onChanged,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un monto';
        }
        final number = double.tryParse(value);
        if (number == null || number <= 0) {
          return 'Ingresa un monto válido mayor a 0';
        }
        return null;
      },
    );
  }

  @override
  State<SBTextField> createState() => _SBTextFieldState();
}

class _SBTextFieldState extends State<SBTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _SBPasswordField extends SBTextField {
  const _SBPasswordField({
    super.key,
    super.controller,
    super.labelText,
    super.hintText,
    super.prefixIcon,
    super.validator,
    super.onChanged,
  });

  @override
  State<SBTextField> createState() => _SBPasswordFieldState();
}

class _SBPasswordFieldState extends State<_SBPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          validator: widget.validator ?? (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 8) {
              return 'La contraseña debe tener al menos 8 caracteres';
            }
            return null;
          },
          onChanged: widget.onChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
