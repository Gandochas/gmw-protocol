import 'package:flutter/material.dart';

final lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 243, 205, 224),
    primary: const Color.fromARGB(255, 206, 142, 163),
    outline: Colors.pink[900],
  ),
);

final darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(surface: Colors.blueGrey[800]!, primary: Colors.blueGrey[400]!),
);
