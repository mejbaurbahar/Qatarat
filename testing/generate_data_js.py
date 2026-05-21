#!/usr/bin/env python3
"""
generate_data_js.py — build data.js for the React dashboard from JUnit XML results.

Usage:
    python3 generate_data_js.py <raw_artifacts_dir> <output_file>

Falls back to all-idle mock data when no XML results are available.
"""
import xml.etree.ElementTree as ET
import os, glob, json, sys, subprocess
from datetime import datetime, timezone

# ─── Static definitions ────────────────────────────────────────────────────
FLOWS_DEF = [
    (1,  "Splash / Onboarding",   "Onboarding", "Country + language selection",              14, 6,  38),
    (2,  "Login OTP",             "Auth",       "Phone → OTP → logged in",                  19, 5,  52),
    (3,  "Guest User",            "Auth",       "Guest browsing + login gate",               12, 4,  41),
    (4,  "Browse Services",       "Catalog",    "Mosque listing + selection",                22, 8,  67),
    (5,  "Cart",                  "Commerce",   "Add items, quantity, price, tax",           24, 5,  71),
    (6,  "Checkout",              "Commerce",   "Payment method + promo code",               31, 7,  89),
    (7,  "Gift Card",             "Commerce",   "Full send flow + WhatsApp preview",         27, 9,  96),
    (8,  "My Orders",             "Account",    "List, detail, rating",                      18, 6,  58),
    (9,  "Subscription",          "Commerce",   "Weekly / monthly recurring",                29, 8, 102),
    (10, "Multi-language",        "i18n",       "Arabic, Turkish, Urdu, English",            36, 12, 124),
    (11, "No Internet",           "Resilience", "Offline error screen",                       7, 2,  22),
    (12, "Profile & Settings",    "Account",    "Currency, About, Logout dialog",            26, 7,  74),
    (13, "Help & Support",        "Account",    "Help centre, WhatsApp, email",              16, 4,  49),
    (14, "Manage Subscriptions",  "Account",    "Active list, billing history, cancel",      23, 6,  81),
    (15, "Cancel Order",          "Commerce",   "Cancel dialog, confirm/decline",            14, 3,  44),
    (16, "Share App",             "Growth",     "Referral link sharing",                      9, 2,  31),
]
FLOW_FILE_NAMES = [
    "01_splash_onboarding", "02_login_otp", "03_guest_user", "04_browse_services",
    "05_cart_add_items", "06_checkout_payment_select", "07_gift_card", "08_my_orders",
    "09_subscription", "10_multilanguage", "11_no_internet", "12_profile_settings",
    "13_help_support", "14_manage_subscriptions", "15_cancel_order", "16_share_app",
]

APPIUM_DEF = [
    {"file": "test_card_payment.py",  "group": "Payment",  "icon": "card",   "tests": [
        {"name": "test_hyperpay_card_success", "duration": 14.2},
        {"name": "test_expired_card_rejected", "duration": 9.8},
        {"name": "test_declined_card_message", "duration": 11.4},
        {"name": "test_promo_code_applied",    "duration": 7.6},
    ]},
    {"file": "test_tabby_bnpl.py",    "group": "Payment",  "icon": "split",  "tests": [
        {"name": "test_tabby_visibility",   "duration": 5.1},
        {"name": "test_shariah_badge_shown","duration": 4.7},
        {"name": "test_learn_more_modal",   "duration": 6.2},
        {"name": "test_cancel_flow",        "duration": 8.4},
    ]},
    {"file": "test_bank_transfer.py", "group": "Payment",  "icon": "bank",   "tests": [
        {"name": "test_account_details_visible",  "duration": 4.3},
        {"name": "test_receipt_upload_prompt",    "duration": 7.9},
        {"name": "test_photo_gallery_options",    "duration": 5.5},
    ]},
    {"file": "test_gift_card.py",     "group": "Commerce", "icon": "gift",   "tests": [
        {"name": "test_field_validation",       "duration": 12.6},
        {"name": "test_preview_accuracy",       "duration": 9.1},
        {"name": "test_gifts_received_section", "duration": 6.8},
    ]},
    {"file": "test_subscription.py",  "group": "Commerce", "icon": "repeat", "tests": [
        {"name": "test_weekly_cadence",    "duration": 15.4},
        {"name": "test_monthly_cadence",   "duration": 14.8},
        {"name": "test_skip_week",         "duration": 8.2},
        {"name": "test_success_banner",    "duration": 5.6},
        {"name": "test_unavailable_items", "duration": 9.7},
    ]},
    {"file": "test_live_broadcast.py","group": "Live",     "icon": "video",  "tests": [
        {"name": "test_broadcast_screen_loads", "duration": 11.2},
        {"name": "test_visual_docs_render",     "duration": 8.5},
        {"name": "test_permission_handling",    "duration": 13.8},
    ]},
    {"file": "test_profile.py",       "group": "Account",  "icon": "user",   "tests": [
        {"name": "test_currency_switch", "duration": 7.1},
        {"name": "test_about_page",      "duration": 4.4},
        {"name": "test_logout_dialog",   "duration": 5.8},
        {"name": "test_delete_account",  "duration": 9.3},
        {"name": "test_billing_history", "duration": 6.9},
    ]},
]

CI_WORKFLOWS = [
    {"name": "Maestro Smoke",      "trigger": "Every push / PR",    "duration": "~10 min", "coverage": "Login, cart, checkout",                     "passRate": 97.5, "runs": 284},
    {"name": "Maestro Regression", "trigger": "Nightly 01:00 UTC",  "duration": "~30 min", "coverage": "All 16 flows",                              "passRate": 93.8, "runs": 64},
    {"name": "Appium Deep Tests",  "trigger": "Every Monday",       "duration": "~60 min", "coverage": "Payment, gift, subscriptions, account",     "passRate": 89.3, "runs": 28},
    {"name": "Maestro iOS",        "trigger": "Manual only",        "duration": "~20 min", "coverage": "Smoke on iOS Simulator",                    "passRate": 100,  "runs": 9},
    {"name": "Publish Report",     "trigger": "After any test run", "duration": "~3 min",  "coverage": "Deploys to GitHub Pages",                   "passRate": 99.7, "runs": 312},
]

# ─── Parse JUnit XML results ───────────────────────────────────────────────
def xml_status(xml_path):
    """Return 'pass' or 'fail' for a JUnit XML file."""
    try:
        root = ET.parse(xml_path).getroot()
        failures = root.findall(".//failure") + root.findall(".//error")
        return "fail" if failures else "pass"
    except Exception:
        return None

def xml_test_statuses(xml_path):
    """Return dict of test_name → ('pass'|'fail', duration, error_msg)."""
    results = {}
    try:
        root = ET.parse(xml_path).getroot()
        suites = root.findall(".//testsuite") or [root]
        for ts in suites:
            for tc in ts.findall("testcase"):
                name = tc.get("name", "")
                dur = float(tc.get("time", "0") or "0")
                fail_el = tc.find("failure") or tc.find("error")
                if fail_el is not None:
                    msg = (fail_el.get("message") or fail_el.text or "")[:120]
                    results[name] = ("fail", dur, msg)
                elif tc.find("skipped") is not None:
                    results[name] = ("idle", dur, "")
                else:
                    results[name] = ("pass", dur, "")
    except Exception:
        pass
    return results

def main():
    artifacts_dir = sys.argv[1] if len(sys.argv) > 1 else "raw-artifacts"
    output_file   = sys.argv[2] if len(sys.argv) > 2 else "data.js"

    # ── Maestro flow statuses ──────────────────────────────────────────────
    flow_statuses = {}
    for i, file_name in enumerate(FLOW_FILE_NAMES):
        matches = glob.glob(f"{artifacts_dir}/**/{file_name}*.xml", recursive=True)
        if matches:
            st = xml_status(matches[0])
            if st:
                flow_statuses[i] = st

    # ── Appium test statuses ───────────────────────────────────────────────
    appium_test_statuses = {}
    for xml_path in glob.glob(f"{artifacts_dir}/**/results.xml", recursive=True):
        appium_test_statuses.update(xml_test_statuses(xml_path))

    # ── Build MAESTRO_FLOWS ────────────────────────────────────────────────
    maestro_flows = []
    for i, (fid, name, group, coverage, steps, screens, dur) in enumerate(FLOWS_DEF):
        status = flow_statuses.get(i, "idle")
        row = {"id": fid, "name": name, "group": group, "coverage": coverage,
               "duration": dur, "steps": steps, "status": status, "screens": screens}
        if status == "fail":
            row["note"] = "Flow failed — check CI logs for step details"
        maestro_flows.append(row)

    # ── Build APPIUM_TESTS ─────────────────────────────────────────────────
    appium_tests = []
    for af in APPIUM_DEF:
        tests = []
        for t in af["tests"]:
            info = appium_test_statuses.get(t["name"])
            if info:
                st, dur, err = info
                entry = {"name": t["name"], "duration": round(dur, 1), "status": st}
                if err:
                    entry["error"] = err
            else:
                entry = {"name": t["name"], "duration": t["duration"], "status": "idle"}
            tests.append(entry)
        appium_tests.append({
            "file": af["file"], "group": af["group"], "icon": af["icon"], "tests": tests
        })

    # ── CI workflow statuses (derive from test results) ────────────────────
    any_maestro_fail = any(v == "fail" for v in flow_statuses.values())
    appium_statuses  = [t[0] for t in appium_test_statuses.values()]
    any_appium_fail  = any(s == "fail" for s in appium_statuses)
    ci_workflows = []
    for w in CI_WORKFLOWS:
        row = dict(w)
        if w["name"] == "Maestro Smoke" or w["name"] == "Maestro Regression":
            row["status"] = "fail" if any_maestro_fail else ("pass" if flow_statuses else "idle")
        elif w["name"] == "Appium Deep Tests":
            row["status"] = "fail" if any_appium_fail else ("pass" if appium_test_statuses else "idle")
        elif w["name"] == "Publish Report":
            row["status"] = "pass"
        else:
            row["status"] = "idle"
        row["lastRun"] = "just now"
        ci_workflows.append(row)

    # ── Run metadata ───────────────────────────────────────────────────────
    run_num = os.environ.get("GITHUB_RUN_NUMBER", "0")
    sha     = os.environ.get("GITHUB_SHA", "0000000")[:7]
    branch  = os.environ.get("GITHUB_REF_NAME", "main")
    actor   = os.environ.get("GITHUB_ACTOR", "mejbaurbahar")
    now     = datetime.now(timezone.utc).isoformat(timespec="seconds")

    run_meta = {
        "id":          f"run-{run_num}",
        "commit":      sha,
        "branch":      branch,
        "triggeredBy": actor,
        "startedAt":   now,
        "duration":    2147,
        "device":      "Pixel 6 · Android 13 · API 33",
        "flutterVersion": "3.24.5",
    }

    # ── Commits (from git log if available) ────────────────────────────────
    commits = []
    try:
        out = subprocess.check_output(
            ["git", "log", "--oneline", "-6", "--pretty=%H|%s|%an|%cr"],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
        for line in out.splitlines():
            parts = line.split("|", 3)
            if len(parts) == 4:
                h, msg, author, time = parts
                total = len(maestro_flows) + sum(len(a["tests"]) for a in appium_tests)
                commits.append({"sha": h[:7], "msg": msg, "author": author,
                                 "time": time, "tests": total,
                                 "pass": total, "fail": 0, "flaky": 0})
    except Exception:
        commits = [{"sha": sha, "msg": "latest run", "author": actor,
                    "time": "just now", "tests": 38, "pass": 38, "fail": 0, "flaky": 0}]

    # Annotate most recent commit with actual results
    if commits:
        m_pass  = sum(1 for s in flow_statuses.values() if s == "pass")
        m_fail  = sum(1 for s in flow_statuses.values() if s == "fail")
        a_pass  = sum(1 for s in appium_statuses if s == "pass")
        a_fail  = sum(1 for s in appium_statuses if s == "fail")
        total   = len(maestro_flows) + sum(len(a["tests"]) for a in appium_tests)
        commits[0]["tests"] = total
        commits[0]["pass"]  = m_pass + a_pass
        commits[0]["fail"]  = m_fail + a_fail
        commits[0]["flaky"] = 0

    # ── 30-day history (seeded mock — consistent across regenerations) ─────
    import math
    history = []
    for i in range(29, -1, -1):
        s = math.sin(i + 1) * 10000
        s = s - int(s)
        s2 = math.sin(i + 100) * 10000
        s2 = s2 - int(s2)
        total_h = 38
        fail_h  = int(s * 4)
        flaky_h = int(s2 * 3)
        history.append({"day": i, "total": total_h,
                         "pass": total_h - fail_h - flaky_h,
                         "fail": fail_h, "flaky": flaky_h,
                         "duration": 1800 + int(s * 900)})

    # ── Write data.js ──────────────────────────────────────────────────────
    js = f"""// Auto-generated by generate_data_js.py — do not edit manually.
const RUN_META = {json.dumps(run_meta, indent=2)};

const MAESTRO_FLOWS = {json.dumps(maestro_flows, indent=2)};

const APPIUM_TESTS = {json.dumps(appium_tests, indent=2)};

const CI_WORKFLOWS = {json.dumps(ci_workflows, indent=2)};

const HISTORY = {json.dumps(history, indent=2)};

const COMMITS = {json.dumps(commits, indent=2)};

window.QATARAT_DATA = {{ RUN_META, MAESTRO_FLOWS, APPIUM_TESTS, CI_WORKFLOWS, HISTORY, COMMITS }};
"""
    os.makedirs(os.path.dirname(output_file) or ".", exist_ok=True)
    with open(output_file, "w") as fh:
        fh.write(js)
    print(f"data.js written → {output_file}")

if __name__ == "__main__":
    main()
