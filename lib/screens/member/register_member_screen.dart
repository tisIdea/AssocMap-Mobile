import 'package:flutter/material.dart';

import '../../models/registration.dart';
import '../../controllers/app_controller.dart';
import '../../theme/app_theme.dart';

class RegisterMemberScreen extends StatefulWidget {
  final AppController controller;
  const RegisterMemberScreen({super.key, required this.controller});

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _birthday;
  String? _sex;
  String? _beneficiaryType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the member\'s date of birth.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final registration = Registration(
      associationId: widget.controller.session!.associationId,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthday: _birthday!,
      sex: _sex!,
      beneficiaryType: _beneficiaryType ?? '',
    );

    try {
      final saved = await widget.controller.register(registration);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _formKey.currentState!.reset();
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      setState(() {
        _birthday = null;
        _sex = null;
        _beneficiaryType = null;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PendingScreen(registration: saved)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _dateText() {
    if (_birthday == null) return 'Select date of birth';
    return '${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        const Text(
          'Register New Member',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Submit a new member registration for Field Officer review.',
          style: TextStyle(color: AppColors.grayText),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please check the applicant?s details. Your Field Officer will review the registration before membership is confirmed.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle name (optional)',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: _required,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _selectBirthday,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _dateText(),
                    style: TextStyle(
                      color: _birthday == null
                          ? AppColors.grayText
                          : AppColors.darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _sex = value),
                validator: (value) => value == null ? 'Select sex.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _beneficiaryType,
                decoration: const InputDecoration(
                  labelText: 'Beneficiary type (optional)',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Fisherfolk',
                    child: Text('Fisherfolk'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _beneficiaryType = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Registration',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class PendingScreen extends StatelessWidget {
  final Registration registration;
  const PendingScreen({super.key, required this.registration});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration Submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryBlue,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Registration Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '${registration.fullName} has been submitted for review.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grayText, fontSize: 16),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The official member list is not changed until the Field Officer reviews the application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grayText, fontSize: 13),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
