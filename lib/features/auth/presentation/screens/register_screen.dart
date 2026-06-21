import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_models.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../main.dart' show registerFcmToken;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    required this.role,
    this.googleUserData,
  });
  final String role;
  final GoogleUserData? googleUserData;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _businessType = 'Restaurant';
  LatLng _markerPosition = const LatLng(27.7172, 85.3240);
  bool _isGeocoding = false;
  bool _isGettingGps = false;
  late bool _isGoogleSignUp;
  final _mapController = MapController();

  // Major cities, towns, and districts across Nepal
  static const _nepalLocations = [
    'Kathmandu', 'Lalitpur (Patan)', 'Bhaktapur', 'Pokhara', 'Biratnagar',
    'Birgunj', 'Dharan', 'Butwal', 'Bharatpur', 'Hetauda', 'Itahari',
    'Janakpur', 'Nepalgunj', 'Dhangadhi', 'Tulsipur', 'Siddharthanagar',
    'Lahan', 'Rajbiraj', 'Triyuga', 'Mechinagar', 'Damak', 'Urlabari',
    'Bhadrapur', 'Ilam', 'Taplejung', 'Diktel', 'Solukhumbu', 'Okhaldhunga',
    'Khotang', 'Udayapur', 'Sindhuli', 'Ramechhap', 'Dolakha', 'Sindhupalchok',
    'Kavrepalanchok (Dhulikhel)', 'Nuwakot', 'Rasuwa', 'Dhading', 'Makwanpur',
    'Rautahat', 'Bara', 'Parsa', 'Sarlahi', 'Mahottari', 'Dhanusa',
    'Siraha', 'Saptari', 'Sunsari', 'Morang', 'Jhapa', 'Panchthar',
    'Terhathum', 'Sankhuwasabha', 'Bhojpur', 'Kanchanpur (Mahendranagar)',
    'Dadeldhura', 'Darchula', 'Baitadi', 'Doti', 'Achham', 'Bajura',
    'Bajhang', 'Humla', 'Mugu', 'Kalikot', 'Jumla', 'Dolpa', 'Mustang',
    'Manang', 'Gorkha', 'Lamjung', 'Kaski', 'Syangja', 'Tanahu',
    'Nawalparasi', 'Rupandehi', 'Kapilvastu', 'Arghakhanchi', 'Gulmi',
    'Palpa', 'Baglung', 'Parbat', 'Myagdi', 'Pyuthan', 'Rolpa', 'Rukum',
    'Salyan', 'Surkhet', 'Dailekh', 'Jajarkot', 'Banke', 'Bardiya',
    'Dang', 'Kailali (Dhangadhi)', 'Nawalpur', 'Parasi',
  ];

  static const _businessTypes = [
    'Restaurant',
    'Cafe',
    'Bakery',
    'Grocery',
    'Sweets',
    'Other',
  ];

  bool get isVendor => widget.role == 'VENDOR';

  @override
  void initState() {
    super.initState();
    _isGoogleSignUp = widget.googleUserData != null;
    // Auto-fill Google data if available
    if (_isGoogleSignUp) {
      _nameCtrl.text = widget.googleUserData!.name;
      _emailCtrl.text = widget.googleUserData!.email;
      _phoneCtrl.text = widget.googleUserData!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return;
    setState(() => _isGeocoding = true);
    try {
      final results = await geo.locationFromAddress('$address, Nepal');
      if (results.isNotEmpty && mounted) {
        final pos = LatLng(results.first.latitude, results.first.longitude);
        setState(() => _markerPosition = pos);
        _mapController.move(pos, 14);
        context.showSnackBar('Location found on map');
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(
            'Could not find that address. Try being more specific.');
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _getGpsLocation() async {
    setState(() => _isGettingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) context.showErrorSnackBar('Please enable location services.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) context.showErrorSnackBar('Location permission denied.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await geo.placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (mounted) {
        final pos = LatLng(position.latitude, position.longitude);
        setState(() {
          _markerPosition = pos;
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              p.street,
              p.subLocality,
              p.locality,
              p.administrativeArea,
            ].where((s) => s != null && s.isNotEmpty).toList();
            _addressCtrl.text = parts.join(', ');
          }
        });
        _mapController.move(pos, 15);
        context.showSnackBar('Current location detected');
      }
    } catch (_) {
      if (mounted) context.showErrorSnackBar('Could not get your location.');
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isGoogleSignUp) {
      final token = widget.googleUserData?.firebaseIdToken;
      if (token == null) return;
      await ref.read(authProvider.notifier).completeGoogleSignIn(
            token,
            widget.role,
            businessName: isVendor ? _businessNameCtrl.text.trim() : null,
            businessType: isVendor ? _businessType : null,
            address: isVendor ? _addressCtrl.text.trim() : null,
            lat: isVendor ? _markerPosition.latitude : null,
            lng: isVendor ? _markerPosition.longitude : null,
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          );
      return;
    }

    final request = RegisterRequest(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: widget.role,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      businessName: isVendor ? _businessNameCtrl.text.trim() : null,
      businessType: isVendor ? _businessType : null,
      address: isVendor ? _addressCtrl.text.trim() : null,
      lat: isVendor ? _markerPosition.latitude : null,
      lng: isVendor ? _markerPosition.longitude : null,
    );
    await ref.read(authProvider.notifier).register(request);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        context.showErrorSnackBar(next.message);
      } else if (next is AuthAuthenticated) {
        registerFcmToken(ref.read(dioClientProvider));
        final user = next.user;
        if (user.isAdmin) {
          context.go('/admin/dashboard');
        } else if (user.isVendor) {
          context.go('/vendor/dashboard');
        } else {
          context.go('/customer/home');
        }
      }
    });

    void navigateBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/register');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(isVendor ? 'Register Business' : 'Create Account'),
          backgroundColor: AppColors.surfaceLight,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: navigateBack,
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s4),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.s2),
                    // Section: personal info
                    const _SectionLabel(
                      icon: Icons.person_outline_rounded,
                      label: 'Personal Information',
                    ),
                    const SizedBox(height: AppSizes.s3),
                    AppTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Name'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.s3),
                    AppTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.email,
                      textInputAction: TextInputAction.next,
                      enabled: !_isGoogleSignUp,
                      suffixIcon: _isGoogleSignUp
                          ? const Icon(Icons.verified,
                              color: AppColors.success, size: 20)
                          : null,
                    ),
                    const SizedBox(height: AppSizes.s3),
                    AppTextField(
                      label: 'Phone number (optional)',
                      hint: '+977 98XXXXXXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.nepalPhone,
                      textInputAction: isVendor
                          ? TextInputAction.next
                          : TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.s6),
                    // Section: security (only for email/password sign-ups)
                    if (!_isGoogleSignUp) ...[
                      const _SectionLabel(
                        icon: Icons.lock_outline_rounded,
                        label: 'Security',
                      ),
                      const SizedBox(height: AppSizes.s3),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordCtrl,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: Validators.password,
                        helperText: 'Minimum 8 characters',
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSizes.s2),
                      _PasswordStrengthBar(password: _passwordCtrl.text),
                      const SizedBox(height: AppSizes.s2),
                      AppTextField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordCtrl,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) =>
                            Validators.confirmPassword(v, _passwordCtrl.text),
                        textInputAction: isVendor
                            ? TextInputAction.next
                            : TextInputAction.done,
                      ),
                      const SizedBox(height: AppSizes.s6),
                    ] else ...[
                      // Google sign-up notice
                      Container(
                        padding: const EdgeInsets.all(AppSizes.s3),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border:
                              Border.all(color: AppColors.success, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: AppSizes.s2),
                            Expanded(
                              child: Text(
                                'Your Google account is securely linked. No password needed.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.s6),
                    ],
                    if (isVendor) ...[
                      const SizedBox(height: AppSizes.s6),
                      // Section: business info
                      const _SectionLabel(
                        icon: Icons.store_outlined,
                        label: 'Business Information',
                      ),
                      const SizedBox(height: AppSizes.s3),
                      AppTextField(
                        label: 'Business Name',
                        controller: _businessNameCtrl,
                        prefixIcon: Icons.store_outlined,
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Business name'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSizes.s3),
                      DropdownButtonFormField<String>(
                        initialValue: _businessType,
                        decoration: InputDecoration(
                          labelText: 'Business Type',
                          filled: true,
                          fillColor: AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusInput),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusInput),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusInput),
                            borderSide: const BorderSide(
                              color: AppColors.borderFocus,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: AppColors.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                        ),
                        items: _businessTypes
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _businessType = v!),
                      ),
                      const SizedBox(height: AppSizes.s3),
                      // GPS button
                      OutlinedButton.icon(
                        onPressed: _isGettingGps ? null : _getGpsLocation,
                        icon: _isGettingGps
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded,
                                color: AppColors.primaryMedium),
                        label: Text(
                          _isGettingGps
                              ? 'Detecting location...'
                              : 'Use my current location',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryMedium),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s3, vertical: AppSizes.s2),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusInput),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.s3),
                      // City search autocomplete
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          final query =
                              textEditingValue.text.toLowerCase().trim();
                          if (query.isEmpty) return const [];
                          return _nepalLocations.where((city) =>
                              city.toLowerCase().contains(query));
                        },
                        onSelected: (city) {
                          _addressCtrl.text = city;
                          _geocodeAddress();
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) {
                          // Sync external controller changes to autocomplete
                          controller.text = _addressCtrl.text;
                          _addressCtrl.addListener(() {
                            if (controller.text != _addressCtrl.text) {
                              controller.text = _addressCtrl.text;
                            }
                          });
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (v) => _addressCtrl.text = v,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _geocodeAddress(),
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Address'),
                            decoration: InputDecoration(
                              labelText: 'Business Address',
                              hintText: 'e.g. Thamel, Kathmandu',
                              filled: true,
                              fillColor: AppColors.neutral50,
                              prefixIcon: const Icon(Icons.location_on_outlined,
                                  color: AppColors.textSecondary),
                              suffixIcon: (_isGeocoding || _isGettingGps)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search_rounded,
                                          color: AppColors.primaryMedium),
                                      tooltip: 'Find on map',
                                      onPressed: _geocodeAddress,
                                    ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusInput),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusInput),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusInput),
                                borderSide: const BorderSide(
                                    color: AppColors.borderFocus, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusInput),
                                borderSide:
                                    const BorderSide(color: AppColors.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusInput),
                                borderSide: const BorderSide(
                                    color: AppColors.error, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final city = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.location_city_outlined,
                                          size: 18,
                                          color: AppColors.primaryMedium),
                                      title: Text(city,
                                          style: AppTextStyles.bodySmall),
                                      onTap: () => onSelected(city),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.s4),
                      // Map picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pin your location on the map',
                              style: AppTextStyles.h5),
                          const SizedBox(height: AppSizes.s1),
                          Text(
                            'Tap the city search or GPS button above, or tap the map to place the pin manually.',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: AppSizes.s3),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            child: Container(
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusLg),
                              ),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _markerPosition,
                                  initialZoom: 13,
                                  onTap: (_, point) {
                                    setState(() => _markerPosition = point);
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.foodrescue.nepal',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _markerPosition,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: AppColors.primaryMedium,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSizes.s8),
                    AppButton(
                      label: isVendor ? 'Register Business' : 'Create Account',
                      onPressed: isLoading ? null : _register,
                      isLoading: isLoading,
                      icon: isVendor
                          ? Icons.store_rounded
                          : Icons.person_add_rounded,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: AppTextStyles.bodySmall),
                        TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s2),
                          ),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _legalConsentText(context),
                    const SizedBox(height: AppSizes.s4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ), // PopScope
    );
  }
}

Widget _legalConsentText(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
            fontSize: 12, color: Color(0xFF888888), height: 1.6),
        children: [
          const TextSpan(text: 'By registering, you agree to our '),
          TextSpan(
            text: 'Terms & Conditions',
            style: const TextStyle(
              color: Color(0xFF2d8c57),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/terms'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Color(0xFF2d8c57),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/privacy'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primaryMedium),
        ),
        const SizedBox(width: AppSizes.s2),
        Text(
          label,
          style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.password});
  final String password;

  static const _labels = ['Weak', 'Fair', 'Strong'];
  static const _colors = [
    AppColors.error,
    AppColors.accentAmber,
    AppColors.success
  ];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = Validators.passwordStrengthScore(password); // 0, 1, or 2
    final color = _colors[score];
    final label = _labels[score];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
              3,
              (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: i <= score ? color : AppColors.neutral200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $label',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
