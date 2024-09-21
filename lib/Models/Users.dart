class Users {
  final int userID;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String profilePicture;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int follower;
  final int following;
  final int point;
  final bool verified; // Change to bool

  Users({
    required this.userID,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.profilePicture,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
    required this.follower,
    required this.following,
    required this.point,
    required this.verified, // Change to bool
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      userID: json["id"] ?? 0,
      username: json["Username"] ?? '',
      password: json["Password"] ?? '',
      email: json["Email"] ?? '',
      fullName: json["FullName"] ?? '',
      dateOfBirth: DateTime.tryParse(json["DateOfBirth"] ?? '') ?? DateTime.now(),
      gender: json["Gender"] ?? '',
      profilePicture: json["ProfilePicture"] ?? '',
      bio: json["Bio"] ?? '',
      createdAt: DateTime.tryParse(json["CreatedAt"] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["UpdatedAt"] ?? '') ?? DateTime.now(),
      follower: json["Follower"] ?? 0,
      following: json["Following"] ?? 0,
      point: json["Point"] ?? 0,
      verified: json["Verified"] ?? false, // Handle boolean values
    );
  }

  Map<String, dynamic> toJson() => {
    "UserID": userID,
    "Username": username,
    "Password": password,
    "Email": email,
    "FullName": fullName,
    "DateOfBirth": dateOfBirth.toIso8601String(),
    "Gender": gender,
    "ProfilePicture": profilePicture,
    "Bio": bio,
    "CreatedAt": createdAt.toIso8601String(),
    "UpdatedAt": updatedAt.toIso8601String(),
    "Follower": follower,
    "Following": following,
    "Point": point,
    "Verified": verified, // Serialize as boolean
  };

  @override
  String toString() {
    return 'Users{userID: $userID, username: $username, email: $email, fullName: $fullName, dateOfBirth: $dateOfBirth, gender: $gender, bio: $bio, createdAt: $createdAt, updatedAt: $updatedAt, follower: $follower, following: $following, point: $point, verified: $verified}';
  }
}
