class Book {
  final int? id;
  final String title;
  final String author;
  final double price;
  final String image;
  final String description;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.image,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'price': price,
      'image': image,
      'description': description,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      price: (map['price'] as num).toDouble(),
      image: map['image'] as String,
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
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
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
