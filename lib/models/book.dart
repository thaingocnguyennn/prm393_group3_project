class Book {
  final int? id;
  final String title;
  final String author;
  final double price;
  final String image;
  final String description;
  final int? categoryId;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.image,
    required this.description,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'price': price,
      'image': image,
      'description': description,
      'categoryId': categoryId,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      price: (map['price'] as num).toDouble(),
      image: map['image'] as String,
      categoryId: map['categoryId'] as int?,
      description: map['description'] as String,
    );
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    double? price,
    String? image,
    String? description,
    int? categoryId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  String toString() =>
      'Book(id: $id, title: $title, author: $author, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Book && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
