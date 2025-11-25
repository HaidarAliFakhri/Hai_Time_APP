import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserFirebaseModel {
  String? uid;
  String? username; // untuk profile
  String? name; // display name
  String? email;
  String? createdAt;
  String? updatedAt;
  String? profileUrl;

  UserFirebaseModel({
    this.uid,
    this.username,
    this.name,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.profileUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      "profileUrl": profileUrl,
    };
  }

  factory UserFirebaseModel.fromMap(Map<String, dynamic> map) {
    return UserFirebaseModel(
      uid: map['uid'],
      username: map['username'],
      name: map['name'],
      email: map['email'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      profileUrl: map["profileUrl"],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserFirebaseModel.fromJson(String source) =>
      UserFirebaseModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
