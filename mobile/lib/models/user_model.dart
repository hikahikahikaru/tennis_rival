/// ユーザー情報を管理するデータモデルクラス
class UserModel {
  /// ユーザーの一意なID (UUID形式)
  final String id;

  /// 表示用のユーザー名 (例: 「たけし」「西やん」など)
  final String name;

  const UserModel({
    required this.id,
    required this.name,
  });

  /// Supabase / データベースのJSONマップから [UserModel] インスタンスを生成するファクトリ
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] as String,
      name: json['user_name'] as String,
    );
  }

  /// インスタンスをJSONマップ形式に変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'user_name': name,
    };
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
