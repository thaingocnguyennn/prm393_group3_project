import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_group3_project/providers/auth_provider.dart';
import 'package:prm393_group3_project/providers/book_provider.dart';
import 'package:prm393_group3_project/providers/cart_provider.dart';
import 'package:prm393_group3_project/utils/app_theme.dart';

// ─── STUB AUTH PROVIDER ───────────────────────────────────────────────────────
// Prevents real DB calls during widget tests.
class _StubAuthProvider extends AuthProvider {
  bool _loading = false;
  String? _error;

  @override
  bool get isLoading => _loading;

  @override
  String? get errorMessage => _error;

  @override
  bool get isLoggedIn => false;

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void setError(String? v) {
    _error = v;
    notifyListeners();
  }

  @override
  Future<bool> login(String username, String password) async {
    if (username == 'testuser' && password == 'password') {
      return true;
    }
    _error = 'Invalid username or password.';
    notifyListeners();
    return false;
  }

  @override
  Future<bool> register(String username, String password) async {
    return true;
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

Widget _buildTestWidget({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
          create: (_) => _StubAuthProvider()),
      ChangeNotifierProvider(create: (_) => BookProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.theme,
      home: child,
    ),
  );
}

// ─── MINIMAL LOGIN FORM (self-contained for widget testing) ──────────────────

class _TestLoginForm extends StatefulWidget {
  const _TestLoginForm();

  @override
  State<_TestLoginForm> createState() => _TestLoginFormState();
}

class _TestLoginFormState extends State<_TestLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                key: const Key('usernameField'),
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Username is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('passwordField'),
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('loginButton'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final auth = context.read<AuthProvider>();
                    final ok = await auth.login(
                        _usernameCtrl.text, _passwordCtrl.text);
                    setState(
                            () => _message = ok ? 'Login success' : 'Login failed');
                  }
                },
                child: const Text('Login'),
              ),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  key: const Key('resultMessage'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TESTS ────────────────────────────────────────────────────────────────────

void main() {
  group('Login Form Widget Tests', () {
    testWidgets('Login form renders username and password fields',
            (tester) async {
          await tester.pumpWidget(
              _buildTestWidget(child: const _TestLoginForm()));

          expect(find.byKey(const Key('usernameField')), findsOneWidget);
          expect(find.byKey(const Key('passwordField')), findsOneWidget);
          expect(find.byKey(const Key('loginButton')), findsOneWidget);
        });

    testWidgets('Shows validation error when fields are empty', (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(child: const _TestLoginForm()));

      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('Shows password length validation error', (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(child: const _TestLoginForm()));

      await tester.enterText(
          find.byKey(const Key('usernameField')), 'testuser');
      await tester.enterText(find.byKey(const Key('passwordField')), '123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'),
          findsOneWidget);
    });

    testWidgets('Successful login shows success message', (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(child: const _TestLoginForm()));

      await tester.enterText(
          find.byKey(const Key('usernameField')), 'testuser');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resultMessage')), findsOneWidget);
      expect(find.text('Login success'), findsOneWidget);
    });

    testWidgets('Failed login shows failure message', (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(child: const _TestLoginForm()));

      await tester.enterText(
          find.byKey(const Key('usernameField')), 'wronguser');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'wrongpass');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(find.text('Login failed'), findsOneWidget);
    });
  });

  group('Add Book Form Widget Tests', () {
    Widget buildAddBookForm() {
      final titleCtrl = TextEditingController();
      final priceCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      return _buildTestWidget(
        child: Scaffold(
          body: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('titleField'),
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('priceField'),
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Price is required';
                      final p = double.tryParse(v);
                      if (p == null || p <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('saveButton'),
                    onPressed: () => formKey.currentState!.validate(),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Shows validation errors on empty Add Book form',
            (tester) async {
          await tester.pumpWidget(buildAddBookForm());

          await tester.tap(find.byKey(const Key('saveButton')));
          await tester.pump();

          expect(find.text('Title is required'), findsOneWidget);
          expect(find.text('Price is required'), findsOneWidget);
        });

    testWidgets('Shows error for invalid (negative) price', (tester) async {
      await tester.pumpWidget(buildAddBookForm());

      await tester.enterText(find.byKey(const Key('titleField')), 'My Book');
      await tester.enterText(find.byKey(const Key('priceField')), '-5');
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pump();

      expect(find.text('Enter a valid price'), findsOneWidget);
    });

    testWidgets('Valid input passes form validation', (tester) async {
      await tester.pumpWidget(buildAddBookForm());

      await tester.enterText(find.byKey(const Key('titleField')), 'Clean Code');
      await tester.enterText(find.byKey(const Key('priceField')), '29.99');
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pump();

      // No error messages should appear
      expect(find.text('Title is required'), findsNothing);
      expect(find.text('Price is required'), findsNothing);
      expect(find.text('Enter a valid price'), findsNothing);
    });
  });
}
