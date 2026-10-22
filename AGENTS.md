# AGENTS.md — sidik-pelanggan-mobile (customer app, view-only)

Agents (Codex, GPT, Claude): read `docs/HANDOFF-CODEX.md` first (full Sidik handoff, 22 Oct 2026).
API rules for the customer module live in the API repo `AGENTS.md` §Modul Pelanggan.

Hard rules (short):
- Customer app is READ-ONLY; write requests are allow-listed (`test/guard_tulis_test.dart`).
- Release: bump `version:` in pubspec.yaml (build number must increase), then `tool/rilis.ps1` —
  it refuses debug-signed APKs. Never print or commit `android/key.properties` / keystore.
- PR to `main` with green CI; never push to `main` directly.
- Release client (`lib/services/klien_rilis.dart`) must never send auth headers to github.com.
