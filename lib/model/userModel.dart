import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class userModel with ChangeNotifier {
  String? name;
  String? uid;

  Future<void> fetchUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('userId');
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('users').child(uid!).child('name');
    DataSnapshot snapshot = (await ref.once()).snapshot;
    name = snapshot.value as String?;
  }

  String? getName() {
    return name;
  }

  String? getUid() {
    return uid;
  }
}