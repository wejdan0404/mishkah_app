class TaskItem {
  TaskItem({
    required this.id,
    required this.label,
    this.isCompleted = false,
  });

  final String id;
  final String label;
  final bool isCompleted;

  TaskItem copyWith({String? label, bool? isCompleted}) {
    return TaskItem(
      id: id,
      label: label ?? this.label,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'isCompleted': isCompleted,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      label: json['label'] as String,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}
