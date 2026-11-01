import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firestore Data Update',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const UpdateStudentPage(),
    );
  }
}

class UpdateStudentPage extends StatefulWidget {
  const UpdateStudentPage({super.key});

  @override
  State<UpdateStudentPage> createState() => _UpdateStudentPageState();
}

class _UpdateStudentPageState extends State<UpdateStudentPage> {
  final CollectionReference<Map<String, dynamic>> students = FirebaseFirestore
      .instance
      .collection('students');

  // Correct Firestore document ID
  final String documentId = 'qD5FmiOt9dvn9L2w9qjW';

  final nameController = TextEditingController();
  final regController = TextEditingController();
  final deptController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isUpdating = false;

  String? errorMessage;

  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    loadStudent();
  }

  // LOAD EXISTING STUDENT DATA
  Future<void> loadStudent() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final doc = await students.doc(documentId).get();

      debugPrint('Document ID: ${doc.id}');
      debugPrint('Document Exists: ${doc.exists}');
      debugPrint('Document Data: ${doc.data()}');

      if (!doc.exists) {
        throw Exception('Student document not found. Check document ID.');
      }

      final data = doc.data()!;

      if (!mounted) return;

      nameController.text = data['name']?.toString() ?? '';
      regController.text = data['registerNumber']?.toString() ?? '';
      deptController.text = data['department']?.toString() ?? '';
      emailController.text = data['email']?.toString() ?? '';

      setState(() {
        studentData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('FIRESTORE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        studentData = null;
        errorMessage = e.toString();
      });
    }
  }

  // UPDATE STUDENT DATA
  Future<void> updateStudent() async {
    if (nameController.text.trim().isEmpty ||
        regController.text.trim().isEmpty ||
        deptController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));

      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      await students.doc(documentId).update({
        'name': nameController.text.trim(),
        'registerNumber': regController.text.trim(),
        'department': deptController.text.trim(),
        'email': emailController.text.trim(),
      });

      // Read updated data from Firestore
      final updatedDoc = await students.doc(documentId).get();

      if (!updatedDoc.exists) {
        throw Exception('Updated document not found');
      }

      final updatedData = updatedDoc.data()!;

      if (!mounted) return;

      setState(() {
        studentData = updatedData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  // TEXT FIELD
  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.edit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Data Update'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Unable to load student record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(errorMessage!, textAlign: TextAlign.center),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: loadStudent,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const Icon(Icons.edit_note, size: 70, color: Colors.indigo),

                  const SizedBox(height: 10),

                  const Text(
                    'Update Student Details',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  buildField('Student Name', nameController),

                  buildField('Register Number', regController),

                  buildField('Department', deptController),

                  buildField('Email', emailController),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : updateStudent,

                      icon: const Icon(Icons.update),

                      label: Text(isUpdating ? 'Updating...' : 'Update Record'),

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Updated Student Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (studentData != null)
                    Card(
                      elevation: 3,

                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(
                          studentData!['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text(
                          'Register No: ${studentData!['registerNumber']}\n'
                          'Department: ${studentData!['department']}\n'
                          'Email: ${studentData!['email']}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    regController.dispose();
    deptController.dispose();
    emailController.dispose();

    super.dispose();
  }
}
