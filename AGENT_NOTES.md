# SecuroApp — AI Agent Handoff Notes
> Last updated: 5 Apr 2026 | Branch: `develop` | Last commit: `e87b7a1`

---

## 1. Project Overview

**SecuroApp** is a Flutter password manager + TOTP authenticator.
- **Mobile** (Android/iOS): Full auth flow — register → login → vault
- **Web / Desktop** (Windows, Linux, macOS): QR-only — scan from mobile to mirror vault

---

## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.22+ / Dart 3.3+ |
| UI | Material 3 (`useMaterial3: true`) |
| Database | Drift 2.31.0 — `sqlite3.wasm` + `drift_worker.dart.js` for web |
| Auth storage | `flutter_secure_storage` (uses localStorage on web) |
| Encryption | AES-256-CBC, PBKDF2-SHA256 key derivation — `EncryptionService` |
| WebSocket relay | Node.js server on port 8080 — LAN IP `192.168.1.39` |
| QR sync | E2EE via session key = sha256(qrToken + sessionId) |

---

## 3. Directory Structure (Key Files)

```
lib/
├── main.dart                          ← App entry point, EncryptionService bootstrap
├── app.dart                           ← MaterialApp, web→WebConnectScreen, mobile→SplashScreen
├── core/
│   ├── theme/app_theme.dart           ← AppTheme tokens (primary=0xFF6C63FF, surface=0xFF1A1A2E)
│   └── utils/responsive.dart         ← Breakpoints: mobileMax=600, tabletMax=900
├── database/
│   └── app_database.dart             ← Drift DB: insertPassword, deleteAllPasswords, watchAllPasswords etc.
├── features/
│   ├── vault/vault_screen.dart        ← Password list, grid (3-col desktop, 2-col tablet, 1-col mobile)
│   ├── authenticator/                 ← TOTP screen
│   ├── generator/                     ← Password generator
│   └── settings/settings_screen.dart ← Profile card (listens to AuthService.profileChangeStream)
├── screens/
│   ├── web_connect_screen.dart        ← Web/desktop landing: QR code, M3 design, 360px column
│   ├── web_home_screen.dart           ← Web/desktop app shell: NavigationRail + 4 tabs + vault import
│   ├── home_screen.dart               ← Mobile app shell: BottomNav + MaterialBanner for sync status
│   ├── link_device_screen.dart        ← Mobile QR scanner → joins session → fires sendVaultData()
│   ├── login_screen.dart              ← Mobile login → unlocks EncryptionService
│   └── splash_screen.dart            ← Mobile splash → routes to login or signup
├── services/
│   ├── link_service.dart              ← WebSocket singleton: createSession (web), joinSession+sendVaultData (mobile)
│   ├── encryption_service.dart        ← AES-256-CBC, encrypt/decrypt, PBKDF2 deriveKey
│   ├── auth_service.dart              ← flutter_secure_storage: register, unlockVault, getProfile, profileChangeStream
│   ├── totp_service.dart              ← TOTP code generation
│   ├── notification_service.dart      ← Local push notifications
│   └── theme_service.dart             ← Theme persistence
├── models/
│   ├── password_item.dart             ← Drift table model
│   └── totp_account.dart              ← Drift table model
└── widgets/
    └── vault_card.dart               ← Password card widget (grid/list)
```

---

## 4. Critical Architecture Notes

### 4.1 Encryption — Two separate contexts

| Context | How initialized | When |
|---------|----------------|------|
| **Mobile** | `AuthService.unlockVault()` → `initializeFromDerived(storedBytes)` | After login |
| **Web/Desktop** | `main.dart` → `EncryptionService.instance.initialize('securo_web_session_key_v1')` | At app startup |

⚠️ **Web MUST call initialize before any encrypt/decrypt** — the `assert(_initialized)` will crash if not. This is done in `main.dart` before `runApp`.

### 4.2 Vault Sync Flow

```
Mobile (LinkDeviceScreen)
  → scans QR → joinSession() → connected
  → _sendVaultAndDismiss(): unawaited(sendVaultData()) + Navigator.pop()
  
sendVaultData() in link_service.dart:
  → reads passwords (decrypted) + totp + profile from mobile DB/storage
  → JSON encodes → E2EE encrypts with session key → sends over WebSocket

Web (WebConnectScreen._onData)
  → receives decrypted Map → Navigator.pushReplacement(WebHomeScreen(initialVaultData: data))

WebHomeScreen.initState()
  → _importVaultData(data):
      1. deleteAllPasswords() + deleteAllTotp()  ← prevents duplicates on re-scan
      2. re-encrypts passwords with web key → insertPassword()
      3. insertTotp()
      4. updateProfile(username, email) → fires profileChangeStream
      
_ProfileCard in SettingsScreen
  → listens to AuthService.profileChangeStream → calls _load() → shows updated name/email
```

### 4.3 NavigationRail — CRITICAL constraint rule

> ⚠️ **NEVER use `SizedBox(width: double.infinity)`** or `double.infinity` width inside `NavigationRail` `leading`/`trailing`. The rail passes unconstrained width → `hasSize: false` paint assertion crash.

**Correct pattern** (used in `web_home_screen.dart`):
```dart
leading: SizedBox(
  width: isDesktop ? 220 : 72,  // ← exact fixed width
  child: Padding(...),
),
trailing: SizedBox(
  width: isDesktop ? 220 : 72,
  child: Padding(...),
),
```

Also set `groupAlignment: -1.0` to left-align destinations at top.

### 4.4 Mobile Background Sync (no UI takeover)

After QR scan + connect:
1. `LinkDeviceScreen._sendVaultAndDismiss()` — `_dismissed` guard prevents double-fire
2. `unawaited(_link.sendVaultData())` — fires and forgets
3. `Navigator.pop()` — immediately returns to `HomeScreen`
4. `HomeScreen._onLinkState` — wrapped in `addPostFrameCallback` to avoid showing banner before Scaffold is active
5. Shows `MaterialBanner` while syncing → success/error `SnackBar` on completion

---

## 5. Sidebar Code Location

The **sidebar (NavigationRail)** appears in TWO places:

| File | Lines | Used for |
|------|-------|---------|
| `lib/screens/web_home_screen.dart` | ~200–290 | Web/Desktop — full M3 NavigationRail with brand logo, 220px extended width, `groupAlignment: -1.0` |
| `lib/screens/home_screen.dart` | ~130–185 | Mobile tablet/desktop — simpler NavigationRail inside `isWide` branch |

---

## 6. Known Patterns

### VaultCard grid overflow
- `vault_screen.dart` grid: `mainAxisExtent: 120` (was 110, caused overflow)
- `vault_card.dart`: `vertical: 10` padding, `mainAxisSize: MainAxisSize.min`, `SizedBox(height: 4)` between username and chip

### Profile refresh on web
- `AuthService.profileChangeStream` (static `StreamController.broadcast()`)
- `_ProfileCardState` subscribes in `initState`, cancels in `dispose`
- `updateProfile()` and `updateAvatarPath()` both fire the stream

---

## 7. What Has Been Committed vs Local

### ✅ Committed to `develop` (SHA `e87b7a1`)
- Initial `web_connect_screen.dart` (QR-centered)
- Initial `web_home_screen.dart` (shell only, no data import)

### 🟡 Done Locally — NOT YET COMMITTED
User has said: **"Do not push until I say ok"**

| File | Changes |
|------|---------|
| `lib/main.dart` | Web/desktop EncryptionService bootstrap |
| `lib/screens/web_connect_screen.dart` | Full M3 overhaul |
| `lib/screens/web_home_screen.dart` | Crash fix + data import + profile save + duplicate prevention + M3 UI |
| `lib/screens/link_device_screen.dart` | Background sync with `_dismissed` guard |
| `lib/screens/home_screen.dart` | Sync MaterialBanner + postFrameCallback |
| `lib/services/link_service.dart` | Profile data added to sync payload |
| `lib/services/auth_service.dart` | `profileChangeStream` added |
| `lib/features/settings/settings_screen.dart` | `_ProfileCard` listens to profileChangeStream |
| `lib/database/app_database.dart` | `deleteAllPasswords()` + `deleteAllTotp()` added |
| `lib/widgets/vault_card.dart` | Overflow fix |
| `lib/features/vault/vault_screen.dart` | `mainAxisExtent: 120` |

---

## 8. Pending / Not Done

- [ ] Avatar photo sync (not sent over WebSocket — only username + email)
- [ ] Web Settings screen: some tiles (Biometric, Import/Export, Drive Backup) are mobile-only features — they will silently fail on web. Should add `kIsWeb` guards or hide them.
- [ ] Auto-refresh vault on web after re-scan without full page navigation
- [ ] Commit approval from user ("ok")

---

## 9. Run & Build

```bash
# Web (dev)
flutter run -d chrome --web-port 5000

# Android
flutter run -d <device-id>

# Analyze
flutter analyze --no-pub

# Relay server (Node.js, must be running for QR sync)
# Located outside Flutter project — runs on port 8080
# LAN IP: 192.168.1.39
```

---

## 10. Theme Tokens

```dart
// lib/core/theme/app_theme.dart
primary   = Color(0xFF6C63FF)   // purple
secondary = Color(0xFF03DAC5)   // teal  
surface   = Color(0xFF1A1A2E)   // dark navy
cardColor = Color(0xFF1E1E30)
error     = Color(0xFFCF6679)
success   = Color(0xFF4CAF50)
```
