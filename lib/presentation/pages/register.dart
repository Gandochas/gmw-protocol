import 'dart:async';

import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final emailPattern = r'^\S+@\S+\.\S+$';

  bool validateEmail(String email) => RegExp(emailPattern).hasMatch(email);

  Future<void> register() async {
    //! add more complex logic :D
    if (_formKey.currentState!.validate()) {
      await Navigator.pushNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Page'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('Hello! Welcome to GMW Protocol App'),
                    const Text('Please fill in the following fields'),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter a password';
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Your first name (Alex, Mark, etc.)',
                        label: Text('Input your first name'),
                      ),
                    ),
                    TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter your email';
                        if (!validateEmail(_emailController.text)) return 'Please enter a valid email';
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Your email (user3236@st.guap.ru)',
                        label: Text('Input your email address'),
                      ),
                    ),
                    TextFormField(
                      controller: _usernameController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter a password';
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Your username (Cocahonka)',
                        label: Text('Input your username'),
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter a password';
                        if (_passwordController.text.length < 8) return 'Your password must be at least 8 characters';
                        if (!_passwordController.text.contains(RegExp(r'[`~!@#$%\^&*\(\)_+\\\-={}\[\]\/.,<>;]'))) {
                          return 'Your password must contain at least 1 special character';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(hintText: 'Your password', label: Text('Input your password')),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: register, child: const Text('Login to your account')),
            ],
          ),
        ),
      ),
    );
  }
}
