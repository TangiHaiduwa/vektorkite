import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/booking/application/booking_controller.dart';
import 'package:vektorkite/features/booking/application/booking_state.dart';
import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_request_draft.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class BookingCreateScreen extends ConsumerStatefulWidget {
  const BookingCreateScreen({
    super.key,
    this.initialCategoryId,
    this.initialSubcategoryId,
    this.initialProviderId,
    this.initialDescription,
  });

  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final String? initialProviderId;
  final String? initialDescription;

  @override
  ConsumerState<BookingCreateScreen> createState() =>
      _BookingCreateScreenState();
}

class _BookingCreateScreenState extends ConsumerState<BookingCreateScreen> {
  static const List<String> _steps = <String>[
    'Details',
    'Schedule',
    'Location',
    'Budget',
    'Review',
  ];

  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  int _stepIndex = 0;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isScheduled = false;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _selectedSubcategoryId = widget.initialSubcategoryId;
    if (widget.initialDescription != null &&
        widget.initialDescription!.trim().isNotEmpty) {
      _descriptionController.text = widget.initialDescription!.trim();
    }
    Future<void>.microtask(
      () => ref.read(bookingControllerProvider.notifier).initializeForm(),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _scheduledAt ?? now,
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  bool _validateCurrentStep() {
    switch (_stepIndex) {
      case 0:
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          _showError('Select a category.');
          return false;
        }
        if (_selectedSubcategoryId == null || _selectedSubcategoryId!.isEmpty) {
          _showError('Select a subcategory.');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Enter service details.');
          return false;
        }
        return true;
      case 1:
        if (_isScheduled && _scheduledAt == null) {
          _showError('Pick a scheduled date and time.');
          return false;
        }
        return true;
      case 2:
        if (_addressController.text.trim().isEmpty) {
          _showError('Enter your address.');
          return false;
        }
        if (_areaController.text.trim().isEmpty) {
          _showError('Enter city/area for matching.');
          return false;
        }
        return true;
      case 3:
        final min = _parseBudget(_budgetMinController.text);
        final max = _parseBudget(_budgetMaxController.text);
        if (min != null && max != null && min > max) {
          _showError('Minimum budget cannot be greater than maximum budget.');
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  double? _parseBudget(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAutoMatch() async {
    if (!_validateAllSteps()) return;
    final controller = ref.read(bookingControllerProvider.notifier);
    final user = await Amplify.Auth.getCurrentUser();

    final booking = await controller.createBooking(
      BookingCreateInput(
        customerId: user.userId,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        providerId: widget.initialProviderId,
        description: _descriptionController.text.trim(),
        addressText: _addressController.text.trim(),
        isScheduled: _isScheduled,
        scheduledFor: _scheduledAt,
        status: BookingStatus.requested,
        estimatedMin: _parseBudget(_budgetMinController.text),
        estimatedMax: _parseBudget(_budgetMaxController.text),
        customerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        lat: double.tryParse(_latController.text.trim()),
        lng: double.tryParse(_lngController.text.trim()),
      ),
    );
    if (!mounted || booking == null) return;
    context.go(
      RoutePaths.bookingConfirmation.replaceFirst(':bookingId', booking.id),
    );
  }

  bool _validateAllSteps() {
    final previousStep = _stepIndex;
    for (var step = 0; step < _steps.length - 1; step++) {
      _stepIndex = step;
      if (!_validateCurrentStep()) {
        setState(() {});
        return false;
      }
    }
    _stepIndex = previousStep;
    setState(() {});
    return true;
  }

  void _chooseProviderFlow() {
    if (!_validateAllSteps()) return;
    final draft = BookingRequestDraft(
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId!,
      description: _descriptionController.text.trim(),
      addressText: _addressController.text.trim(),
      cityArea: _areaController.text.trim(),
      isScheduled: _isScheduled,
      scheduledFor: _scheduledAt,
      budgetMin: _parseBudget(_budgetMinController.text),
      budgetMax: _parseBudget(_budgetMaxController.text),
      customerNote: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      lat: double.tryParse(_latController.text.trim()),
      lng: double.tryParse(_lngController.text.trim()),
    );
    context.push(RoutePaths.bookingProviderSelection, extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Create Booking'),
      ),
      body: SafeArea(
        child: bookingState.isLoading && bookingState.categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFDFE),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${_stepIndex + 1} of ${_steps.length}: ${_steps[_stepIndex]}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_stepIndex + 1) / _steps.length,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(_steps.length, (index) {
                              final active = index <= _stepIndex;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFE6F6F3)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _steps[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? const Color(0xFF0F766E)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStepContent(bookingState, controller),
                        if (bookingState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          AppInlineError(
                            message: bookingState.errorMessage!,
                            onRetry: () => controller.initializeForm(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        if (_stepIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: bookingState.isSubmitting
                                  ? null
                                  : () => setState(() => _stepIndex -= 1),
                              child: const Text('Back'),
                            ),
                          ),
                        if (_stepIndex > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _stepIndex == _steps.length - 1
                              ? ElevatedButton(
                                  onPressed: bookingState.isSubmitting
                                      ? null
                                      : _confirmAutoMatch,
                                  child: bookingState.isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Confirm & Auto-match'),
                                )
                              : ElevatedButton(
                                  onPressed: bookingState.isSubmitting
                                      ? null
                                      : () {
                                          if (!_validateCurrentStep()) return;
                                          setState(() => _stepIndex += 1);
                                        },
                                  child: const Text('Continue'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStepContent(BookingState state, BookingController controller) {
    return switch (_stepIndex) {
      0 => _detailsStep(state, controller),
      1 => _scheduleStep(),
      2 => _locationStep(),
      3 => _budgetStep(),
      _ => _reviewStep(state),
    };
  }

  Widget _detailsStep(BookingState state, BookingController controller) {
    return _stepPanel(
      title: 'What service do you need?',
      subtitle: 'Start with category, then add details for better matching.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: state.categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                _selectedCategoryId = value;
                _selectedSubcategoryId = null;
              });
              await controller.loadSubcategories(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubcategoryId,
            decoration: const InputDecoration(labelText: 'Subcategory'),
            items: state.subcategories
                .map(
                  (subcategory) => DropdownMenuItem<String>(
                    value: subcategory.id,
                    child: Text(subcategory.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedSubcategoryId = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
              hintText: 'Include scope, quantity, and urgency.',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional note (optional)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleStep() {
    return _stepPanel(
      title: 'When should this happen?',
      subtitle: 'Choose immediate request or schedule for later.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Now')),
              ButtonSegment<bool>(value: true, label: Text('Schedule')),
            ],
            selected: <bool>{_isScheduled},
            onSelectionChanged: (selection) {
              setState(() {
                _isScheduled = selection.first;
                if (!_isScheduled) _scheduledAt = null;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_isScheduled)
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.event),
              label: Text(
                _scheduledAt == null
                    ? 'Choose date and time'
                    : DateFormat('EEE, dd MMM yyyy HH:mm').format(_scheduledAt!),
              ),
            )
          else
            const Text('Request will be sent immediately for matching.'),
        ],
      ),
    );
  }

  Widget _locationStep() {
    return _stepPanel(
      title: 'Where is the job location?',
      subtitle: 'This helps us match relevant providers.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Full address',
              hintText: 'Street, suburb, city',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'City/Area',
              hintText: 'Used for provider filtering',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude (optional)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude (optional)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _fillCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Use current location'),
          ),
        ],
      ),
    );
  }

  Widget _budgetStep() {
    return _stepPanel(
      title: 'Budget (optional)',
      subtitle: 'Give a range to improve match quality.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _budgetMinController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Min budget (NAD)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _budgetMaxController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Max budget (NAD)'),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep(BookingState state) {
    String? categoryName;
    for (final category in state.categories) {
      if (category.id == _selectedCategoryId) {
        categoryName = category.name;
        break;
      }
    }
    String? subcategoryName;
    for (final subcategory in state.subcategories) {
      if (subcategory.id == _selectedSubcategoryId) {
        subcategoryName = subcategory.name;
        break;
      }
    }

    return Column(
      children: [
        _stepPanel(
          title: 'Review your booking',
          subtitle: 'Confirm details before submitting request.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow('Category', categoryName ?? '-'),
              _reviewRow('Subcategory', subcategoryName ?? '-'),
              _reviewRow('Description', _descriptionController.text.trim()),
              _reviewRow(
                'Schedule',
                _isScheduled
                    ? DateFormat('EEE, dd MMM yyyy HH:mm').format(_scheduledAt!)
                    : 'Now',
              ),
              _reviewRow('Address', _addressController.text.trim()),
              _reviewRow('City/Area', _areaController.text.trim()),
              _reviewRow(
                'Coordinates',
                '${_latController.text.trim().isEmpty ? '-' : _latController.text.trim()}, '
                '${_lngController.text.trim().isEmpty ? '-' : _lngController.text.trim()}',
              ),
              _reviewRow(
                'Budget',
                '${_budgetMinController.text.trim().isEmpty ? '-' : _budgetMinController.text.trim()} to '
                    '${_budgetMaxController.text.trim().isEmpty ? '-' : _budgetMaxController.text.trim()} NAD',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _chooseProviderFlow,
            child: const Text('Choose a provider instead'),
          ),
        ),
      ],
    );
  }

  Widget _stepPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fillCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission not granted.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location.')),
      );
    }
  }
}
