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
    // 兼容 GetUserInfo 各种字段命名（原App前端用 userCode/grade/nickName 等）
    String _s(Object? v) => v?.toString() ?? '';
    return UserModel(
      userId: _s(json['userId'] ?? json['userCode'] ?? json['UserCode']),
      phone: _s(json['phone'] ?? json['mobile']).isNotEmpty
          ? _s(json['phone'] ?? json['mobile'])
          : null,
      nickname: _s(json['nickname'] ?? json['nickName'] ?? json['realName']).isNotEmpty
          ? _s(json['nickname'] ?? json['nickName'] ?? json['realName'])
          : null,
      avatar: _s(json['avatar'] ?? json['headImgUrl'] ?? json['headImg']).isNotEmpty
          ? _s(json['avatar'] ?? json['headImgUrl'] ?? json['headImg'])
          : null,
      token: _s(json['token']).isNotEmpty ? _s(json['token']) : null,
      refreshToken: _s(json['refreshToken'] ?? json['refresh_token']).isNotEmpty
          ? _s(json['refreshToken'] ?? json['refresh_token'])
          : null,
      gradeId: (json['gradeId'] ?? json['gradeId2']) as int?,
      gradeName:
          _s(json['gradeName'] ?? json['grade'] ?? json['gradeCode']).isNotEmpty
              ? _s(json['gradeName'] ?? json['grade'] ?? json['gradeCode'])
              : null,
      schoolName: _s(json['schoolName'] ?? json['school']).isNotEmpty
          ? _s(json['schoolName'] ?? json['school'])
          : null,
      cityName: _s(json['cityName'] ?? json['city'] ?? json['cityCode']).isNotEmpty
          ? _s(json['cityName'] ?? json['city'] ?? json['cityCode'])
          : null,
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