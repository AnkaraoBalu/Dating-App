import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../data/profile_controller.dart';

// Profile screens use the website's forest green with cream text. Surfaces are
// opaque blends of white over the green so sheets and dialogs match too.
const profileBackground = AppColors.forest;
const profileSurface = Color(0xFF2A4E45);
const profileSurfaceSecondary = Color(0xFF35584F);
const profileAccent = AppColors.coral;
const profileAccentSoft = Color(0xFF584A48);
const profileTextPrimary = AppColors.background;
const profileTextSecondary = Color(0xFFC5CAC0);
const profileTextTertiary = Color(0xFF97A59B);
const profileBorder = Color(0xFF3C5E55);
// Lighter mint so success states stand out on the green background.
const profileSuccess = Color(0xFF7FD6AC);

void profileNotice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

Future<bool> profileAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) {
      profileNotice(context, e.toString().replaceFirst('Exception: ', ''));
    }
    return false;
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.actions,
    this.step,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final List<Widget>? actions;
  final int? step;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: profileBackground,
      canvasColor: profileSurface,
      popupMenuTheme: const PopupMenuThemeData(
        color: profileSurface,
        textStyle: TextStyle(color: profileTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: profileBackground,
        foregroundColor: profileTextPrimary,
        titleTextStyle: TextStyle(
          color: profileTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: profileTextPrimary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: profileAccent,
        onPrimary: Colors.white,
        secondary: profileAccent,
        surface: profileSurface,
        onSurface: profileTextPrimary,
        onSurfaceVariant: profileTextSecondary,
        outline: profileBorder,
        outlineVariant: profileBorder,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: profileSurface,
        modalBackgroundColor: profileSurface,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: profileSurface),
      dividerColor: profileBorder,
      chipTheme: Theme.of(
        context,
      ).chipTheme.copyWith(checkmarkColor: profileTextPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: profileSurfaceSecondary,
        labelStyle: const TextStyle(color: profileTextSecondary),
        floatingLabelStyle: const TextStyle(color: profileTextPrimary),
        hintStyle: const TextStyle(color: profileTextTertiary),
        helperStyle: const TextStyle(color: profileTextSecondary),
        counterStyle: const TextStyle(color: profileTextTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: profileBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: profileBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: profileAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: profileAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: profileAccent, width: 1.5),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: profileTextPrimary),
      ),
      iconTheme: const IconThemeData(color: profileTextSecondary),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: profileTextPrimary,
        displayColor: profileTextPrimary,
      ),
    ),
    child: Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: profileBackground,
        foregroundColor: profileTextPrimary,
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (step != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: step! / 5,
                        color: profileAccent,
                        backgroundColor: profileBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$step/5',
                      style: const TextStyle(
                        color: profileTextTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: bottom,
              ),
            ),
    ),
  );
}

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: profileAccent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: busy
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.title,
    this.value,
    required this.icon,
    this.onTap,
    this.trailing,
  });
  final String title;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: profileSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: profileBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: profileAccent, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: value == null ? profileTextPrimary : profileTextSecondary,
            fontSize: value == null ? 14 : 12,
          ),
        ),
        subtitle: value == null
            ? null
            : Text(
                value!.isEmpty ? 'Not added' : value!,
                style: TextStyle(color: profileTextPrimary, fontSize: 14),
              ),
        trailing:
            trailing ??
            (onTap == null
                ? null
                : Icon(Icons.chevron_right, color: profileTextSecondary)),
        onTap: onTap,
      ),
    ),
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            color: profileTextPrimary,
            fontSize: 17,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: const TextStyle(color: profileTextSecondary, fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

class ProfilePhotoView extends StatelessWidget {
  const ProfilePhotoView(this.url, {super.key, this.fit = BoxFit.cover});
  final String? url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => url == null || url!.isEmpty
      ? const ColoredBox(
          color: AppColors.surfaceSecondary,
          child: Center(
            child: Icon(
              Icons.person_outline,
              color: AppColors.textTertiary,
              size: 64,
            ),
          ),
        )
      : Image.network(
          url!,
          fit: fit,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppColors.surface,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );
}

class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.controller,
    required this.onSave,
    this.label = 'Continue →',
  });
  final ProfileController controller;
  final Future<void> Function() onSave;
  final String label;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => ProfileButton(
      label: label,
      busy: controller.saving,
      onPressed: () async {
        await profileAction(context, onSave);
      },
    ),
  );
}
