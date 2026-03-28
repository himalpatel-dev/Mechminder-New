import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../service/api_service.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _pendingTodos = [];
  List<Todo> _completedTodos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Todo> get pendingTodos => _pendingTodos;
  List<Todo> get completedTodos => _completedTodos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> pending = await ApiService.getPendingTodos();
      _pendingTodos = pending.map((t) => Todo.fromMap(t)).toList();

      final List<dynamic> completed = await ApiService.getCompletedTodos();
      _completedTodos = completed.map((t) => Todo.fromMap(t)).toList();
    } catch (e) {
      _errorMessage = "Could not refresh tasks. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(int id, String status) async {
    await ApiService.updateTodoStatus(id, status);
    await refreshTodos();
  }

  Future<void> deleteTodo(int id) async {
    await ApiService.deleteTodo(id);
    await refreshTodos();
  }

  Future<void> createTodo(Map<String, dynamic> row) async {
    await ApiService.createTodo(row);
    await refreshTodos();
  }
}
