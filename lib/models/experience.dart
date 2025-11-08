class Experience {
  final String id;
  final String name;
  final String imageUrl;
  final String? iconUrl;

  Experience({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.iconUrl,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      iconUrl: json['icon_url'] ?? json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image_url': imageUrl, 'icon_url': iconUrl};
  }
}
