import 'package:flutter/material.dart';

/// بيفتح شاشة جديدة من غير ما يسيب الشاشة اللي تحتها في الذاكرة.
/// (maintainState: false) يعني لما شاشة تغطي الشاشة اللي قبلها، اللي قبلها
/// بتتفرّغ وصورها بتتشال من الذاكرة، ولما اللاعب يرجع بترجع تتحمل تاني.
/// كده الموبايل مبيشيلش صور كل شاشات اللعبة مع بعض.
Route<T> gameRoute<T>(Widget screen) => MaterialPageRoute<T>(
      builder: (_) => screen,
      maintainState: false,
    );
