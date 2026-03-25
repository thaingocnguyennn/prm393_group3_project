class News {
  final int? id;
  final String title;
  final String description;
  final String image;
  final DateTime? createdAt;

  News({
    this.id,
    required this.title,
    required this.description,
    required this.image,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory News.fromMap(Map<String, dynamic> map) {
    return News(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      image: map['image'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  News copyWith({
    int? id,
    String? title,
    String? description,
    String? image,
    DateTime? createdAt,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
