class CategoryModel {
  final int? id;
  final String name;
  final String description;

  CategoryModel({
    this.id,
    required this.name,
    required this.description,
  });

  // Chuyển object thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  // Tạo object từ Map đọc ra từ SQLite
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }

  // Dùng khi muốn sửa 1 vài field nhưng giữ field cũ
  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}