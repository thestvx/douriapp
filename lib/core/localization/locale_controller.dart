import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

Locale directionalityOf(Locale locale) => locale;
