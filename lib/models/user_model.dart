/// 用户模型
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
  final String? schoolGuid;
  final String? grade;
  final String? ruCode;
  final String? cityCode;
  final String? studentName;

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
    this.schoolGuid,
    this.grade,
    this.ruCode,
    this.cityCode,
    this.studentName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v?.toString() ?? '';
    String _pick(List keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && _s(v).isNotEmpty) return _s(v);
      }
      return '';
    }
    return UserModel(
      userId: _pick(['userId', 'userCode', 'UserCode']),
      phone: _pick(['phone', 'mobile']).isNotEmpty ? _pick(['phone', 'mobile']) : null,
      // GetUserInfo 解密后昵称/姓名的真实键是 name(上报v.name=吕承阳为证)
      nickname: _pick(['name', 'nickName', 'nickname', 'realName']).isNotEmpty
          ? _pick(['name', 'nickName', 'nickname', 'realName']) : null,
      avatar: _pick(['avatar', 'headImgUrl', 'headImg']).isNotEmpty
          ? _pick(['avatar', 'headImgUrl', 'headImg']) : null,
      token: _pick(['token']).isNotEmpty ? _pick(['token']) : null,
      refreshToken: _pick(['refreshToken', 'refresh_token']).isNotEmpty
          ? _pick(['refreshToken', 'refresh_token']) : null,
      gradeId: (json['gradeId'] ?? json['gradeId2']) as int?,
      gradeName: _pick(['gradeName', 'grade', 'gradeCode']).isNotEmpty
          ? _pick(['gradeName', 'grade', 'gradeCode']) : null,
      schoolName: _pick(['schoolName', 'school']).isNotEmpty
          ? _pick(['schoolName', 'school']) : null,
      cityName: _pick(['cityName', 'city', 'cityCode']).isNotEmpty
          ? _pick(['cityName', 'city']) : null,
      schoolGuid: _pick(['schoolGuid', 'schoolCode', 'guid', 'schoolId']).isNotEmpty
          ? _pick(['schoolGuid', 'schoolCode', 'guid', 'schoolId']) : null,
      grade: _pick(['currentGrade', 'gradeCode', 'gradeId', 'grade']).isNotEmpty
          ? _pick(['currentGrade', 'gradeCode', 'gradeId', 'grade'])
          : _pick(['gradeName', 'grade']).isNotEmpty ? _pick(['gradeName', 'grade']) : null,
      ruCode: _pick(['ruCode', 'regionCode', 'areaCode']).isNotEmpty
          ? _pick(['ruCode', 'regionCode', 'areaCode']) : null,
      cityCode: _pick(['cityCode', 'cityId']).isNotEmpty
          ? _pick(['cityCode', 'cityId']) : null,
      studentName: _pick(['studentName', 'realName', 'name', 'nickname']).isNotEmpty
          ? _pick(['studentName', 'realName', 'name', 'nickname']) : null,
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
        'schoolGuid': schoolGuid,
        'grade': grade,
        'ruCode': ruCode,
        'cityCode': cityCode,
        'studentName': studentName,
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
        schoolGuid: schoolGuid,
        grade: grade,
        ruCode: ruCode,
        cityCode: cityCode,
        studentName: studentName,
      );
}