# Qatarat (قطرات) — Mobile App Test Suite

[![Maestro Smoke](../../actions/workflows/01-maestro-smoke.yml/badge.svg)](../../actions/workflows/01-maestro-smoke.yml)
[![Maestro Regression](../../actions/workflows/02-maestro-regression.yml/badge.svg)](../../actions/workflows/02-maestro-regression.yml)
[![Appium Deep Tests](../../actions/workflows/03-appium-android.yml/badge.svg)](../../actions/workflows/03-appium-android.yml)

**Flutter app** · Android & iOS · Package `com.qatarat.app`

📊 **[View Live Test Report →](https://mejbaurbahar.github.io/Qatarat/)**

---

## Test on your phone (USB) — anyone can do this

```bash
# 1. Clone the repo
git clone https://github.com/mejbaurbahar/Qatarat.git
cd Qatarat/testing

# 2. Install all tools (Java, ADB, Maestro, Appium, Python)
./install.sh
source ~/.zshrc

# 3. Enable USB Debugging on your Android phone:
#    Settings → About Phone → tap Build Number 7 times
#    Settings → Developer Options → turn on USB Debugging
#    Connect phone via USB → tap Allow on the dialog that appears

# 4. Launch the interactive menu
./run_on_device.sh
```

The script detects your phone automatically, installs the app, and shows a menu. No commands to memorise.

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| **App** | Flutter / Dart |
| **UI automation** | [Maestro](https://maestro.mobile.dev) 2.x — YAML flows |
| **Deep tests** | [Appium](https://appium.io) 2.x + `appium-flutter-driver` + `uiautomator2` |
| **Test language** | Python 3 with `pytest` |
| **Reporting** | [Allure](https://allurereport.org) + GitHub Pages dashboard |
| **CI / CD** | GitHub Actions (free — Ubuntu + Android emulator) |
| **Device** | Android API 33 emulator (CI) or any USB Android phone (local) |

---

## CI / CD — GitHub Actions (all free)

| Workflow | Trigger | Duration | Coverage |
|----------|---------|----------|----------|
| Maestro Smoke | Every push / PR | ~10 min | Login, cart, checkout |
| Maestro Regression | Nightly 01:00 UTC | ~30 min | All 16 flows |
| Appium Deep Tests | Every Monday | ~60 min | Payment, gift, subscriptions, account |
| Maestro iOS | Manual only | ~20 min | Smoke on iOS Simulator |
| Publish Report | After any test run | ~3 min | Deploys to GitHub Pages |

**Run any workflow manually:** [Actions tab](../../actions) → pick workflow → **Run workflow**

> **First-time setup:** Go to **Settings → Pages → Source → GitHub Actions** to enable the report page.

---

## What is tested (full coverage)

### Maestro flows (16 flows)

| # | Flow | What it covers |
|---|------|---------------|
| 01 | Splash / Onboarding | Country + language selection |
| 02 | Login OTP | Phone → OTP → logged in |
| 03 | Guest User | Guest browsing + login gate |
| 04 | Browse Services | Mosque listing + selection |
| 05 | Cart | Add items, quantity, price, tax |
| 06 | Checkout | Payment method + promo code |
| 07 | Gift Card | Full send flow + WhatsApp preview |
| 08 | My Orders | List, detail, rating |
| 09 | Subscription | Weekly / monthly recurring |
| 10 | Multi-language | Arabic, Turkish, Urdu, English |
| 11 | No Internet | Offline error screen |
| 12 | Profile & Settings | Currency, About, Logout dialog |
| 13 | Help & Support | Help centre, WhatsApp, email |
| 14 | Manage Subscriptions | Active list, billing history, cancel |
| 15 | Cancel Order | Cancel dialog, confirm/decline |
| 16 | Share App | Referral link sharing |

### Appium deep tests (22 tests)

| File | Tests |
|------|-------|
| `test_card_payment.py` | HyperPay card success, expired card, declined, promo code |
| `test_tabby_bnpl.py` | Tabby visibility, Shariah badge, Learn More, cancel |
| `test_bank_transfer.py` | Account details, receipt upload prompt, photo/gallery options |
| `test_gift_card.py` | Field validation, preview accuracy, gifts received section |
| `test_subscription.py` | Weekly, monthly, skip, success banner, unavailable items |
| `test_live_broadcast.py` | Broadcast screen, visual docs, permission handling |
| `test_profile.py` | Currency, About page, logout dialog, delete account, billing history |

---

## Local commands

```bash
cd testing

./run_on_device.sh              # interactive USB device menu

./run_maestro.sh                # smoke suite
./run_maestro.sh regression     # full regression (all 16 flows)
./run_maestro.sh flow 12        # single flow by number

./run_appium.sh payment         # payment tests
./run_appium.sh gift            # gift card tests
./run_appium.sh subscription    # subscription tests
./run_appium.sh account         # profile & account tests
./run_appium.sh                 # all Appium tests
```
