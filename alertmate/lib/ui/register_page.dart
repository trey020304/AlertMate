import 'package:flutter/material.dart';
import 'package:alertmate/sheets/user_sheets_api.dart';
import 'package:flutter/services.dart'; // For limiting characters on text field

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _passwordStrength = '';
  String _phoneErrorMessage = '';
  bool _isRegistering = false;
  bool _isPasswordHidden = true;

  // Toggles password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  String? _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return "Phone number can't be empty";
    }
    if (phoneNumber.startsWith('09') && phoneNumber.length == 11) {
      return null;
    } else if (phoneNumber.startsWith('9') && phoneNumber.length == 10) {
      return null;
    } else {
      return "Phone number is invalid";
    }
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.length < 8) {
        _passwordStrength = 'Weak';
      } else if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)')
          .hasMatch(password)) {
        _passwordStrength = 'Medium';
      } else {
        _passwordStrength = 'Strong';
      }
    });
  }

  Future<void> _onRegisterPressed() async {
    setState(() {
      _phoneErrorMessage = _validatePhoneNumber(_phoneController.text) ?? '';
    });

    if (_phoneErrorMessage.isEmpty && _passwordController.text.isNotEmpty) {
      setState(() {
        _isRegistering = true;
      });

      try {
        // Check if the phone number already exists
        final phoneExists =
            await UserSheetsApi.doesPhoneNumberExist(_phoneController.text);

        if (phoneExists) {
          // Show error message if phone number exists
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number already exists!')),
          );
        } else {
          // Add phone and password to Users sheet
          await UserSheetsApi.addRowToUsers([
            _phoneController.text, // Phone Number
            _passwordController.text, // Password
          ]);

          // Add phone, tentative name, and address to Profiles sheet
          await UserSheetsApi.addRowToProfiles([
            _phoneController.text, // Phone Number
            'Name (Pending)', // Tentative Name
            'Address (Pending)', // Tentative Address
          ]);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          // Navigate back to login
          Navigator.pop(context);
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      } finally {
        setState(() {
          _isRegistering = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please correct the errors before submitting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/alert-gradient.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF148895),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixText: '(+63)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            floatingLabelStyle: const TextStyle(
                              color: Color(0xFF52A0A9),
                              fontWeight: FontWeight.w300,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF148895)),
                            ),
                            errorText: _phoneErrorMessage.isNotEmpty
                                ? _phoneErrorMessage
                                : null,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                                10), // Limit to 20 characters
                          ],
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordHidden,
                          onChanged: _checkPasswordStrength,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            floatingLabelStyle: const TextStyle(
                              color: Color(0xFF52A0A9),
                              fontWeight: FontWeight.w300,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF148895)),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_passwordController.text.isNotEmpty)
                        Column(
                          children: [
                            SizedBox(
                              width: 300,
                              child: LinearProgressIndicator(
                                value: _passwordStrength == 'Strong'
                                    ? 1.0
                                    : (_passwordStrength == 'Medium'
                                        ? 0.6
                                        : 0.3),
                                backgroundColor: Colors.grey[300],
                                color: _passwordStrength == 'Strong'
                                    ? const Color(0xFF148895)
                                    : (_passwordStrength == 'Medium'
                                        ? Colors.amber
                                        : Colors.red),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Password Strength: $_passwordStrength',
                              style: TextStyle(
                                color: _passwordStrength == 'Strong'
                                    ? const Color(0xFF148895)
                                    : (_passwordStrength == 'Medium'
                                        ? Colors.amber
                                        : Colors.red),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isRegistering ? null : _onRegisterPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF148895),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isRegistering
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(color: Color(0xFF148895)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
