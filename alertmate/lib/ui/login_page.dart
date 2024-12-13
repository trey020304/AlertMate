import 'package:flutter/material.dart';
import 'register_page.dart';
import 'root_page.dart';
import 'package:alertmate/sheets/user_sheets_api.dart' as UserApi;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For limiting characters on text field

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  String _phoneErrorMessage = '';
  bool _isLoggingIn = false;

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

  Future<void> _onLoginPressed() async {
    setState(() {
      _phoneErrorMessage = _validatePhoneNumber(_phoneController.text) ?? '';
    });

    if (_phoneErrorMessage.isEmpty && _passwordController.text.isNotEmpty) {
      setState(() {
        _isLoggingIn = true;
      });

      try {
        final users = await UserApi.UserSheetsApi.getUsers();

        final user = users.firstWhere(
          (user) => user.phone == _phoneController.text,
          orElse: () => UserApi.User(phone: '', password: ''),
        );

        if (user.phone.isEmpty || user.password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number or password.')),
          );
        } else if (user.password == _passwordController.text) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('phone', user.phone);
          await prefs.setString('password', user.password);
          await prefs.setBool('isLoggedIn', true); // Save login state

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RootPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number or password.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoggingIn = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please correct the errors before submitting.')),
      );
    }
  }

  // // Call this method to log out the user
  // Future<void> _logout() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('phone');
  //   await prefs.remove('password');
  //   await prefs.setBool('isLoggedIn', false); // Update login state
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => const LoginPage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Section
                    Center(
                      child: Image.asset(
                        'assets/alert-gradient.png',
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Center(
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF148895),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Phone Number Input
                    Center(
                      child: SizedBox(
                          width: 300, // Adjust width as needed
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
                                borderSide:
                                    BorderSide(color: Color(0xFF148895)),
                              ),
                              errorText: _phoneErrorMessage.isEmpty
                                  ? null
                                  : _phoneErrorMessage,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                  10), // Limit to 10 characters
                            ],
                          )),
                    ),
                    const SizedBox(height: 20),
                    // Password Input
                    Center(
                      child: SizedBox(
                        width: 300, // Adjust width as needed
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordHidden,
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
                    ),
                    const SizedBox(height: 30),
                    // Login Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoggingIn ? null : _onLoginPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF148895),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isLoggingIn
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Log in',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Register Button
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to Register Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Color(0xFF148895)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
