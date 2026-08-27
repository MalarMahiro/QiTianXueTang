class UserModel {
  final String userId;
  final String? phone;
  final String? nickname;
  final String? avatar;
  final String? token;
  final String? refreshToken;
  final int? gradeId;
  final String? gradeName;
  final String? schoolName;
  final String? cityName;

  UserModel({
    required this.userId,
    this.phone,
    this.nickname,
    this.avatar,
    this.token,
    this.refreshToken,
    this.gradeId,
    this.gradeName,
    this.schoolName,
    this.cityName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? '',
      phone: json['phone']?.toString(),
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
      token: json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      gradeId: json['gradeId'] as int?,
      gradeName: json['gradeName']?.toString(),
      schoolName: json['schoolName']?.toString(),
      cityName: json['cityName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'phone': phone,
        'nickname': nickname,
        'avatar': avatar,
        'token': token,
        'refreshToken': refreshToken,
        'gradeId': gradeId,
        'gradeName': gradeName,
        'schoolName': schoolName,
        'cityName': cityName,
      };

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  UserModel copyWith({String? token}) => UserModel(
        userId: userId,
        phone: phone,
        nickname: nickname,
        avatar: avatar,
        token: token ?? this.token,
        refreshToken: refreshToken,
        gradeId: gradeId,
        gradeName: gradeName,
        schoolName: schoolName,
        cityName: cityName,
      );
}