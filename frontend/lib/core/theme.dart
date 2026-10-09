import 'package:flutter/material.dart';

/// Couleurs de la maquette (Tokens.dc.html). Un seul endroit où ces hexas
/// existent : chaque écran va piocher ici plutôt que de retaper
/// `Color(0xFF...)` partout — si Carl change une teinte un jour, un seul
/// fichier à toucher.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF16A34A);
  static const brandDark = Color(0xFF0F7A37);
  static const brandLight = Color(0xFFDCFCE7);

  /// Fond sombre de la carte calories (Accueil) et du bandeau de Connexion.
  static const hero = Color(0xFF123524);

  /// Couleur de l'anneau de calories, sur fond `hero`.
  static const limeAccent = Color(0xFFA3E635);

  static const ink = Color(0xFF14201A);
  static const textSecondary = Color(0xFF5B675F);

  /// Gris un peu plus clair que `textSecondary`, utilisé seulement pour des
  /// icônes secondaires (navigation inactive, flèche de lien) — pas pour du
  /// texte.
  static const iconMuted = Color(0xFF6B776F);

  static const border = Color(0xFFE3E8E1);
  static const fieldFill = Color(0xFFF1F4EF);
  static const background = Color(0xFFF4F6F1);

  /// Le token "erreur" officiel de la maquette est #E5484D, mais partout où
  /// une erreur est vraiment affichée (bandeau de connexion...) la maquette
  /// utilise en fait ce rouge plus foncé sur ce fond rosé clair — probablement
  /// pour le contraste texte/fond (4.5:1). On suit l'usage réel plutôt que le
  /// swatch de la page Tokens.
  static const errorText = Color(0xFFA1191E);
  static const errorBg = Color(0xFFFFE7E8);

  // Chaque nutriment garde la même couleur partout dans l'appli. 3 teintes
  // par famille (pas une seule) : `xxxIcon` est plus soutenu que `xxx` pour
  // rester lisible en trait d'icône sur le fond clair `xxxBg` — une icône
  // dans la couleur "plate" `xxx` serait trop pâle à cette taille.
  static const protein = Color(0xFFF2557A);
  static const proteinBg = Color(0xFFFDE4EB);
  static const proteinIcon = Color(0xFFD63862);

  static const carbs = Color(0xFFF5B228);
  static const carbsBg = Color(0xFFFEF1D3);
  static const carbsIcon = Color(0xFFB87A06);

  static const fat = Color(0xFF7C6CF2);
  static const fatBg = Color(0xFFEAE7FD);
  static const fatIcon = Color(0xFF5B4BD6);

  static const water = Color(0xFF2D9CF0);
  static const waterBg = Color(0xFFDFF0FD);
  static const waterIcon = Color(0xFF1B7FCC);

  static const calories = Color(0xFFFF7A45);
}

/// Rayons de bordure nommés (section "Arrondis" de la maquette). Les tailles
/// d'icônes ponctuelles (14, 20...) ne sont pas ici : ce ne sont pas des
/// tokens nommés dans la maquette, juste des valeurs locales à un composant —
/// seules les 4 tailles qui reviennent partout (cartes, champs, feuilles...)
/// méritent un nom.
class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      // `ColorScheme.fromSeed` dérive tout un jeu de couleurs cohérent (primary,
      // secondary, surfaces...) à partir d'une seule couleur de base — c'est ce
      // qui alimente `Theme.of(context).colorScheme.xxx`, déjà utilisé dans une
      // quinzaine d'écrans (ex: `colorScheme.error` pour les messages d'erreur).
      // On garde ce mécanisme standard Material 3 plutôt que de le remplacer :
      // seuls `primary` et `error` sont forcés sur les couleurs exactes de la
      // maquette, le reste (surfaces, teintes dérivées) peut rester calculé.
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brand,
            brightness: Brightness.light,
          ).copyWith(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            error: AppColors.errorText,
          ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // "chiffre clé" (34/800) de la maquette : pas un slot standard de
        // `TextTheme`, Material 3 n'a rien d'assez grand/gras pour un gros
        // nombre isolé — `displayMedium` est le slot le plus proche sans
        // collision avec un usage déjà pris ailleurs.
        displayMedium: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.ink,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.ink,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        // "overline" (12/800, majuscules, +0.8 d'espacement) : Material 3 a
        // retiré le slot `overline` historique. `labelSmall` est repris pour
        // ce rôle — chaque écran qui veut ce style de petit libellé de
        // section doit en plus poser `.toUpperCase()` et
        // `letterSpacing`/`textTransform` n'existant pas nativement, voir
        // FLUTTER.md.
        labelSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      // `StadiumBorder` (pas `BorderRadius.circular(999)`) : une pilule dont
      // la hauteur change (ex: un bouton avec un label plus long qui passe sur
      // 2 lignes) doit rester parfaitement ronde aux extrémités quelle que
      // soit sa hauteur réelle — un rayon fixe de 999 donnerait un rayon trop
      // petit par rapport à la nouvelle hauteur et casserait l'effet pilule.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandDark,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.errorText, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
