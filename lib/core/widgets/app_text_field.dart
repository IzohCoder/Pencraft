import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.suffix,
    this.prefix,
    this.prefixText,
    this.suffixText,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? suffix;
  final Widget? prefix;
  final String? prefixText;
  final String? suffixText;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        focusNode: focusNode,
        autofocus: autofocus,
        readOnly: readOnly,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        onTap: onTap,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          suffix: suffix,
          prefix: prefix,
          prefixText: prefixText,
          suffixText: suffixText,
          counterText: '',
        ),
      ),
    );
  }
}
