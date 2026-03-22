class UserModel {
  final String firebaseUid;
  final String? fcmToken;
  final String? purchaseId;
  final DateTime? updatedAt;

  UserModel({
    required this.firebaseUid,
    this.fcmToken,
    this.purchaseId,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firebaseUid: json['firebase_uid'],
      fcmToken: json['fcm_token'],
      purchaseId: json['purchase_id'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebase_uid': firebaseUid,
      'fcm_token': fcmToken,
      'purchase_id': purchaseId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
