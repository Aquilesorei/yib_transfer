


import 'package:flutter/material.dart';


class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool? obscure;
  final void Function(String)? onSubmitted;

  const PasswordTextField({super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.obscure,
    this.onSubmitted
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  late bool isObscureText;

  @override
  void initState() {
    super.initState();
    isObscureText = widget.obscure ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        obscureText: isObscureText,
        controller: widget.controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
          hintText: widget.hintText,
          suffixIcon: widget.obscure != null
              ? IconButton(
            onPressed: () {
              setState(() {
                isObscureText = !isObscureText;
              });
            },
            icon: Icon(
              isObscureText ? Icons.visibility : Icons.visibility_off,
            ),
          )
              : null,
        ),
        onSubmitted:widget.onSubmitted,
      ),
    );
  }
}
