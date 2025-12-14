import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'dart:convert';

// --- Models ---
class AdminUser {
  final int id;
  final String username;
  final String email;
  final String? premiumUntil;
  final bool isAdmin;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    this.premiumUntil,
    required this.isAdmin,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      premiumUntil: json['premiumUntil'],
      isAdmin: json['isAdmin'] == 1 || json['isAdmin'] == true,
    );
  }
}

// Model for Admin Dashboard Statistics
class AdminStats {
  final int totalUsers;
  final int premiumUsers;
  final List<RecentSignup> recentSignups;

  AdminStats({
    required this.totalUsers,
    required this.premiumUsers,
    required this.recentSignups,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'],
      premiumUsers: json['premiumUsers'],
      recentSignups: (json['recentSignups'] as List)
          .map((i) => RecentSignup.fromJson(i))
          .toList(),
    );
  }
}

// Model for Recent Signups within AdminStats
class RecentSignup {
  final int id;
  final String username;
  final String email;
  final String createdAt; // Assuming ISO 8601 string from API

  RecentSignup({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory RecentSignup.fromJson(Map<String, dynamic> json) {
    return RecentSignup(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      createdAt: json['createdAt'],
    );
  }
}

// Model for Admin Question Moderation
class AdminQuestion {
  final int id;
  final String questionText;
  final String? answerText;
  final bool isFromAi;
  final String createdAt;
  final String ownerUsername;
  final String ownerEmail;

  AdminQuestion({
    required this.id,
    required this.questionText,
    this.answerText,
    required this.isFromAi,
    required this.createdAt,
    required this.ownerUsername,
    required this.ownerEmail,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    return AdminQuestion(
      id: json['id'],
      questionText: json['questionText'],
      answerText: json['answerText'],
      isFromAi: json['isFromAi'] == 1 || json['isFromAi'] == true, // Handle int or bool
      createdAt: json['createdAt'],
      ownerUsername: json['ownerUsername'],
      ownerEmail: json['ownerEmail'],
    );
  }
}

// Model for User Activity Insights
class UserActivity {
  final int totalQuestionsAsked;
  final int totalAnswersGiven;
  final int totalQuizzesCreated; // NEW: Add totalQuizzesCreated

  UserActivity({
    required this.totalQuestionsAsked,
    required this.totalAnswersGiven,
    required this.totalQuizzesCreated, // NEW: Add to constructor
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      totalQuestionsAsked: json['totalQuestionsAsked'] ?? 0,
      totalAnswersGiven: json['totalAnswersGiven'] ?? 0,
      totalQuizzesCreated: json['totalQuizzesCreated'] ?? 0, // NEW: Parse totalQuizzesCreated
    );
  }
}

// Model for Admin Quiz Moderation
class AdminQuiz {
  final int id;
  final String title;
  final String? description;
  final String createdAt;
  final String ownerUsername;
  final String ownerEmail;

  AdminQuiz({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.ownerUsername,
    required this.ownerEmail,
  });

  factory AdminQuiz.fromJson(Map<String, dynamic> json) {
    return AdminQuiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: json['createdAt'],
      ownerUsername: json['ownerUsername'],
      ownerEmail: json['ownerEmail'],
    );
  }
}


// --- Admin Login Page ---
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _logIn() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.loginWithEmail(_emailController.text, _passwordController.text);

    if (mounted) {
      if (error == null) {
        final userIsAdmin = authService.currentUser?.isAdmin ?? false;
        if (userIsAdmin) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          await authService.logout();
          setState(() {
            _isLoading = false;
            _errorMessage = 'Access Denied: You are not an administrator.';
          });
        }
      } else {
        setState(() { _isLoading = false; _errorMessage = error; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mystrio Admin Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 24),
                if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _logIn, child: const Text('Log In')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Admin Dashboard Page ---
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Future<AdminStats> _fetchAdminStats(String token) async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final response = await api.get('/admin/stats', token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return AdminStats.fromJson(decoded);
    } else {
      throw Exception('Failed to load admin stats: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final token = authService.authToken;
        if (token == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: const Center(child: Text('Authentication required.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome, Admin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.people),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/users');
                      },
                      label: const Text('Manage Users'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.question_answer),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/questions');
                      },
                      label: const Text('Moderate Questions'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.quiz),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/quizzes');
                      },
                      label: const Text('Moderate Quizzes'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('Overview Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FutureBuilder<AdminStats>(
                  future: _fetchAdminStats(token),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData) {
                      return const Center(child: Text('No stats available.'));
                    }

                    final stats = snapshot.data!;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text('Total Users', style: TextStyle(fontSize: 16)),
                                      Text('${stats.totalUsers}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text('Premium Users', style: TextStyle(fontSize: 16)),
                                      Text('${stats.premiumUsers}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text('Recent Signups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.recentSignups.length,
                          itemBuilder: (context, index) {
                            final signup = stats.recentSignups[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.person_add),
                                title: Text(signup.username),
                                subtitle: Text('${signup.email} - ${signup.createdAt.substring(0, 10)}'),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- User Management Page ---
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<AdminUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<AdminUser>> _fetchUsers() async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');
    
    final response = await api.get('/admin/users', token: token);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => AdminUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  // NEW: Delete user functionality
  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final api = Provider.of<MystrioApi>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.authToken;
      await api.delete('/admin/users/$userId', token: token!);
      _refreshUsers();
    }
  }

  // NEW: Edit user functionality
  Future<void> _showEditUserDialog(AdminUser user) async {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email); // FIX: Corrected typo
    final premiumController = TextEditingController(text: user.premiumUntil);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user.username}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: premiumController, decoration: const InputDecoration(labelText: 'Premium Until (YYYY-MM-DD or leave blank)')),
              // NEW: User Activity Section
              const SizedBox(height: 20),
              const Text('User Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FutureBuilder<UserActivity>(
                future: _fetchUserActivity(user.id), // Fetch activity for this user
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error loading activity: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('No activity data.');
                  }
                  final activity = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Questions Asked: ${activity.totalQuestionsAsked}'),
                      Text('Answers Given: ${activity.totalAnswersGiven}'),
                      Text('Quizzes Created: ${activity.totalQuizzesCreated}'), // NEW: Display quizzes created
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final api = Provider.of<MystrioApi>(context, listen: false);
              final authService = Provider.of<AuthService>(context, listen: false);
              final token = authService.authToken;
              
              final Map<String, dynamic> body = {
                'username': usernameController.text,
                'email': emailController.text,
                'premiumUntil': premiumController.text.isEmpty ? null : premiumController.text,
              };

              await api.put('/admin/users/${user.id}', token: token!, body: body);
              Navigator.of(context).pop();
              _refreshUsers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // NEW: Method to fetch user activity
  Future<UserActivity> _fetchUserActivity(int userId) async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');

    final response = await api.get('/admin/users/$userId/activity', token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserActivity.fromJson(decoded);
    } else {
      throw Exception('Failed to load user activity: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: FutureBuilder<List<AdminUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Premium Until')),
                DataColumn(label: Text('Admin')),
                DataColumn(label: Text('Actions')),
              ],
              rows: users.map((user) => DataRow(cells: [
                DataCell(Text(user.id.toString())),
                DataCell(
                  InkWell( // NEW: Make username clickable
                    onTap: () {
                      Navigator.of(context).pushNamed('/user-detail', arguments: user.id);
                    },
                    child: Text(user.username, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                  ),
                ),
                DataCell(Text(user.email)),
                DataCell(Text(user.premiumUntil?.toString() ?? 'N/A')),
                DataCell(Icon(user.isAdmin ? Icons.check_circle : Icons.cancel, color: user.isAdmin ? Colors.green : Colors.grey)),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditUserDialog(user)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(user.id)),
                  ],
                )),
              ])).toList(),
            ),
          );
        },
      ),
    );
  }
}

// NEW: --- User Detail Page ---
class UserDetailPage extends StatefulWidget {
  final int userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<AdminUser> _userFuture;
  late Future<UserActivity> _activityFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser(widget.userId);
    _activityFuture = _fetchUserActivity(widget.userId);
  }

  Future<AdminUser> _fetchUser(int userId) async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');

    // Fetch all users and find the specific one (since we don't have /users/:id endpoint)
    final response = await api.get('/admin/users', token: token);
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      final users = decoded.map((json) => AdminUser.fromJson(json)).toList();
      return users.firstWhere((user) => user.id == userId, orElse: () => throw Exception('User not found'));
    } else {
      throw Exception('Failed to load user details: ${response.body}');
    }
  }

  Future<UserActivity> _fetchUserActivity(int userId) async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');

    final response = await api.get('/admin/users/$userId/activity', token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserActivity.fromJson(decoded);
    } else {
      throw Exception('Failed to load user activity: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<AdminUser>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('User not found.'));
                }
                final user = snapshot.data!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${user.id}', style: const TextStyle(fontSize: 16)),
                        Text('Username: ${user.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Email: ${user.email}', style: const TextStyle(fontSize: 16)),
                        Text('Premium Until: ${user.premiumUntil?.substring(0, 10) ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        Text('Admin: ${user.isAdmin ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Text('User Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<UserActivity>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading activity: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('No activity data.'));
                }
                final activity = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Questions Asked: ${activity.totalQuestionsAsked}', style: const TextStyle(fontSize: 16)),
                        Text('Answers Given: ${activity.totalAnswersGiven}', style: const TextStyle(fontSize: 16)),
                        Text('Quizzes Created: ${activity.totalQuizzesCreated}', style: const TextStyle(fontSize: 16)), // NEW: Display quizzes created
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// --- Question Moderation Page ---
class QuestionModerationPage extends StatefulWidget {
  const QuestionModerationPage({super.key});

  @override
  _QuestionModerationPageState createState() => _QuestionModerationPageState();
}

class _QuestionModerationPageState extends State<QuestionModerationPage> {
  late Future<List<AdminQuestion>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();
  }

  Future<List<AdminQuestion>> _fetchQuestions() async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');

    final response = await api.get('/admin/questions', token: token);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => AdminQuestion.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load questions: ${response.body}');
    }
  }

  void _refreshQuestions() {
    setState(() {
      _questionsFuture = _fetchQuestions();
    });
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final api = Provider.of<MystrioApi>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.authToken;
      await api.delete('/admin/questions/$questionId', token: token!);
      _refreshQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question Moderation')),
      body: FutureBuilder<List<AdminQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No questions found.'));
          }

          final questions = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Question Text')),
                DataColumn(label: Text('Answer Text')),
                DataColumn(label: Text('Owner')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: questions.map((question) => DataRow(cells: [
                DataCell(Text(question.id.toString())),
                DataCell(SizedBox(width: 200, child: Text(question.questionText, overflow: TextOverflow.ellipsis, maxLines: 2))),
                DataCell(SizedBox(width: 200, child: Text(question.answerText ?? 'N/A', overflow: TextOverflow.ellipsis, maxLines: 2))),
                DataCell(Text('${question.ownerUsername} (${question.ownerEmail})')),
                DataCell(Text(question.createdAt.substring(0, 10))),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(question.id)),
                  ],
                )),
              ])).toList(),
            ),
          );
        },
      ),
    );
  }
}

// NEW: --- Quiz Moderation Page ---
class QuizModerationPage extends StatefulWidget {
  const QuizModerationPage({super.key});

  @override
  _QuizModerationPageState createState() => _QuizModerationPageState();
}

class _QuizModerationPageState extends State<QuizModerationPage> {
  late Future<List<AdminQuiz>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = _fetchQuizzes();
  }

  Future<List<AdminQuiz>> _fetchQuizzes() async {
    final api = Provider.of<MystrioApi>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null) throw Exception('Not authenticated');

    final response = await api.get('/admin/quizzes', token: token);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => AdminQuiz.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quizzes: ${response.body}');
    }
  }

  void _refreshQuizzes() {
    setState(() {
      _quizzesFuture = _fetchQuizzes();
    });
  }

  Future<void> _deleteQuiz(int quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final api = Provider.of<MystrioApi>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.authToken;
      await api.delete('/admin/quizzes/$quizId', token: token!);
      _refreshQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Moderation')),
      body: FutureBuilder<List<AdminQuiz>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quizzes found.'));
          }

          final quizzes = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Owner')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: quizzes.map((quiz) => DataRow(cells: [
                DataCell(Text(quiz.id.toString())),
                DataCell(SizedBox(width: 150, child: Text(quiz.title, overflow: TextOverflow.ellipsis, maxLines: 2))),
                DataCell(SizedBox(width: 200, child: Text(quiz.description ?? 'N/A', overflow: TextOverflow.ellipsis, maxLines: 2))),
                DataCell(Text('${quiz.ownerUsername} (${quiz.ownerEmail})')),
                DataCell(Text(quiz.createdAt.substring(0, 10))),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuiz(quiz.id)),
                  ],
                )),
              ])).toList(),
            ),
          );
        },
      ),
    );
  }
}


// --- Main Admin App Entry Point ---
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        Provider(create: (context) => MystrioApi()),
      ],
      child: const MystrioAdminApp(),
    ),
  );
}

class MystrioAdminApp extends StatelessWidget {
  const MystrioAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mystrio Admin',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/dashboard': (context) => const AdminDashboardPage(),
        '/users': (context) => const UserManagementPage(),
        '/questions': (context) => const QuestionModerationPage(),
        '/quizzes': (context) => const QuizModerationPage(), // NEW: Route for quiz moderation
        '/user-detail': (context) => UserDetailPage(userId: ModalRoute.of(context)!.settings.arguments as int), // NEW: User Detail Page Route
      },
    );
  }
}
