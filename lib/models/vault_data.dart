/// Lightweight vault data model for sending over network.
/// Used when mobile server sends data to web/remote client.
class VaultDataModel {
  final List<Map<String, String>> passwords;
  final List<Map<String, String>> totp;

  VaultDataModel({
    this.passwords = const [],
    this.totp = const [],
  });

  factory VaultDataModel.fromJson(Map<String, dynamic> json) {
    return VaultDataModel(
      passwords: (json['passwords'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      totp: (json['totp'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'passwords': passwords,
        'totp': totp,
      };
}
