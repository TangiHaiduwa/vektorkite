import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/features/marketplace/application/store_dashboard_controller.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class StoreDashboardScreen extends ConsumerStatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  ConsumerState<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends ConsumerState<StoreDashboardScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'NAD ');
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(storeDashboardControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDashboardControllerProvider);
    final controller = ref.read(storeDashboardControllerProvider.notifier);
    final store = state.store;

    if (!_hydrated && store != null) {
      _nameController.text = store.name;
      _phoneController.text = store.phone ?? '';
      _cityController.text = store.city;
      _addressController.text = store.address;
      _hydrated = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context) ? const AppBackButton() : null,
        title: const Text('Provider Store Dashboard'),
      ),
      body: !state.isProvider
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.errorMessage != null)
                  AppInlineError(message: state.errorMessage!),
                const Card(
                  child: ListTile(
                    title: Text('Provider-only feature'),
                    subtitle: Text(
                      'Stores and product management are available only for service providers. '
                      'Customers can browse products but cannot create stores or listings.',
                    ),
                  ),
                ),
              ],
            )
          : state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.initialize(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.errorMessage != null)
                    AppInlineError(message: state.errorMessage!),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Profile',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Store name'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Address'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: state.isSaving
                                      ? null
                                      : () async {
                                          final name = _nameController.text.trim();
                                          final city = _cityController.text.trim();
                                          final address = _addressController.text.trim();
                                          if (name.isEmpty ||
                                              city.isEmpty ||
                                              address.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Store name, city and address are required.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          final saved = await controller.saveStore(
                                            StoreUpsertInput(
                                              id: store?.id,
                                              name: name,
                                              phone: _phoneController.text.trim().isEmpty
                                                  ? null
                                                  : _phoneController.text.trim(),
                                              city: city,
                                              address: address,
                                              logoKey: store?.logoKey,
                                            ),
                                          );
                                          if (!context.mounted || saved == null) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Store profile saved.'),
                                            ),
                                          );
                                          _hydrated = false;
                                          await controller.initialize();
                                        },
                                  child: state.isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(store == null ? 'Create Store' : 'Save Store'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${store?.status.name.toUpperCase() ?? 'PENDING'}',
                          ),
                          if (store != null &&
                              store.status != MarketplaceStoreStatus.approved)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Your store must be approved before sponsored listings can be promoted.',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'My Products',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: store == null
                            ? null
                            : () => _openProductEditor(
                                  context: context,
                                  ref: ref,
                                  existing: null,
                                ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.products.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No products listed yet.'),
                        subtitle: Text('Create your first product listing above.'),
                      ),
                    )
                  else
                    ...state.products.map(
                      (product) => Card(
                        child: ListTile(
                          title: Text(product.title),
                          subtitle: Text(
                            '${_currency.format(product.priceNAD)} | Stock ${product.stockQty}\n'
                            'Active: ${product.isActive ? 'Yes' : 'No'} | Sponsored: ${product.isSponsored ? 'Yes' : 'No'}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _openProductEditor(
                                  context: context,
                                  ref: ref,
                                  existing: product,
                                );
                                return;
                              }
                              if (value == 'delete') {
                                final ok = await controller.deleteProduct(product.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'Product deleted.' : 'Unable to delete product.',
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

Future<void> _openProductEditor({
  required BuildContext context,
  required WidgetRef ref,
  required MarketplaceProduct? existing,
}) async {
  final state = ref.read(storeDashboardControllerProvider);
  final controller = ref.read(storeDashboardControllerProvider.notifier);
  final store = state.store;
  if (store == null) return;

  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(
    text: existing?.description ?? '',
  );
  final priceController = TextEditingController(
    text: existing == null ? '' : existing.priceNAD.toStringAsFixed(2),
  );
  final stockController = TextEditingController(
    text: existing?.stockQty.toString() ?? '0',
  );
  String? categoryId = existing?.categoryId;
  String? subcategoryId = existing?.subcategoryId;
  bool isActive = existing?.isActive ?? true;
  bool isSponsored = existing?.isSponsored ?? false;
  final imageKeys = [...(existing?.images ?? const <String>[])];

  if (categoryId != null) {
    await controller.loadSubcategories(categoryId);
  }
  if (!context.mounted) return;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (picked == null) return;
    final uploaded = await controller.uploadProductImage(picked.path);
    if (uploaded == null) return;
    imageKeys.add(uploaded);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final localState = ref.watch(storeDashboardControllerProvider);
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Create Product' : 'Edit Product',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (NAD)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock quantity'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: localState.categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      setSheetState(() {
                        categoryId = value;
                        subcategoryId = null;
                      });
                      if (value != null) {
                        await controller.loadSubcategories(value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: subcategoryId,
                    decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      ...localState.subcategories.map(
                        (subcategory) => DropdownMenuItem<String>(
                          value: subcategory.id,
                          child: Text(subcategory.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        subcategoryId = value == '' ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (value) => setSheetState(() => isActive = value),
                    title: const Text('Product active'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: isSponsored,
                    onChanged: (value) {
                      if (!controller.canToggleSponsored()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Store approval pending. Sponsored placement unavailable.',
                            ),
                          ),
                        );
                        return;
                      }
                      setSheetState(() => isSponsored = value);
                    },
                    title: const Text('Sponsored listing'),
                    subtitle: const Text('Displayed in featured marketplace section.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: imageKeys
                        .map((key) => Chip(label: Text('Image ${imageKeys.indexOf(key) + 1}')))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add product image'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: localState.isSaving
                          ? null
                          : () async {
                              if (categoryId == null ||
                                  categoryId!.isEmpty ||
                                  titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Title and category are required.'),
                                  ),
                                );
                                return;
                              }
                              final price = double.tryParse(priceController.text.trim());
                              final stock = int.tryParse(stockController.text.trim()) ?? 0;
                              if (price == null || price < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid price.'),
                                  ),
                                );
                                return;
                              }
                              final saved = await controller.saveProduct(
                                ProductUpsertInput(
                                  id: existing?.id,
                                  storeId: store.id,
                                  categoryId: categoryId!,
                                  subcategoryId: subcategoryId,
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  priceNAD: price,
                                  images: imageKeys,
                                  stockQty: stock,
                                  isActive: isActive,
                                  isSponsored: isSponsored,
                                ),
                              );
                              if (!context.mounted || saved == null) return;
                              Navigator.of(context).pop();
                            },
                      child: localState.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Product'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

