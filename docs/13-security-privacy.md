# Phase 13 — Security & Privacy

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [02](02-requirements.md), [03](03-architecture.md), [04](04-database-design.md). Related: [decisions/why-offline-first.md](../decisions/why-offline-first.md), [decisions/why-no-ads.md](../decisions/why-no-ads.md).

Privacy is a **core feature**, not a compliance checkbox ([01](01-vision.md)). This document defines
the security model, threat model, and data-handling rules that make the privacy promise real.

---

## 1. Principles
1. **Data minimization** — collect only what a feature needs; default to nothing.
2. **On-device by default** — no data leaves the device without explicit, revocable consent ([NFR-6](02-requirements.md)).
3. **No trackers** — zero ad/analytics SDKs, zero silent telemetry ([NFR-5](02-requirements.md), [why-no-ads.md](../decisions/why-no-ads.md)).
4. **User owns and controls** — export, backup, and irreversible delete are first-class ([08 F14](08-feature-specs.md)).
5. **Defense in depth** — DB integrity + encryption + validation + least privilege.

---

## 2. Threat Model

| Threat | Vector | Mitigation |
|---|---|---|
| **Device theft / loss** | Attacker gains physical device | OS lockscreen + optional app lock; backups encrypted at rest; sensitive keys in platform keystore. |
| **Backup file exfiltration** | User's exported backup copied | Backups **encrypted** (§3); key not stored in the backup. |
| **Malicious/curious app on device** | Another app reads shared storage | App DB in app-private storage; exports only to user-chosen locations via SAF. |
| **Supply-chain (dependency)** | A package adds tracking/exfiltration | Dependency privacy gate ([10 §7](10-coding-standards.md)); no ad/analytics SDKs; pinned versions; review on upgrade. |
| **Import poisoning** | Crafted import file corrupts data/crashes | Strict schema + domain validation on import (§6); transactional, idempotent by UUID. |
| **Over-broad permissions** | App requests more than needed | Minimum permissions, each justified (§8). |
| **Network leak** | Accidental outbound call in core flow | No network in core flows ([NFR-9](02-requirements.md)); any future network feature opt-in + labeled + reviewable. |
| **Future cloud breach** | Server compromise (post-v1) | End-to-end encryption design for sync (§10); server sees only ciphertext. |

**Out of model (v1):** nation-state device compromise, rooted-device tampering beyond OS guarantees —
noted honestly rather than over-promised.

---

## 3. Encryption

| Data | At rest | Approach |
|---|---|---|
| **Backups** ([08 F14](08-feature-specs.md)) | **Encrypted** | Authenticated symmetric encryption (e.g., AES-GCM) via a vetted library; key derived/stored in the Android **Keystore** — never written into the backup or exported in plaintext. |
| **Local DB** | App-private storage; **optional** DB encryption (e.g., SQLCipher-style) evaluated for a later phase | v1 relies on app-private storage + OS user encryption; full at-rest DB encryption is a documented option (perf trade-off measured in [14](14-performance.md)). |
| **Export (JSON/CSV)** | User's choice | Exports are portable/plaintext by design (ownership); the UI **warns** that an unencrypted export is readable and offers the encrypted backup path for safekeeping. |

- Keys live in the platform keystore; they never sync, never appear in logs, never leave the device
  unencrypted ([NFR-7](02-requirements.md)).
- Crypto is delegated to a vetted library — **no hand-rolled cryptography**.

---

## 4. Local Database Security
- DB file resides in **app-private** storage (not world-readable).
- Foreign keys + `CHECK` constraints prevent integrity corruption ([04 §11](04-database-design.md)).
- Transactional writes prevent partial-state corruption ([NFR-13](02-requirements.md)).
- Optional at-rest DB encryption tracked as a future hardening item (§3).

## 5. Export Security
- Export is explicit, user-initiated, to a user-chosen location (SAF).
- Clear warning that plaintext exports are readable by anything with the file.
- Encrypted backup is the recommended path for durable, safe storage.

## 6. Import Validation
- Every imported record is validated against the **domain rules** (value objects) and DB constraints
  before persistence — never trusted blindly.
- Idempotent by **UUID**; conflicts resolved last-write-wins by `updated_at` ([04 §8](04-database-design.md)).
- Malformed/oversized files are rejected with a typed `BackupFailure` ([03 §4](03-architecture.md)); no partial import.

## 7. Privacy Policy (structure — copy pending legal review)
The in-app/store privacy policy will state plainly:
- What is collected (health data the user enters) and where it lives (**on device**).
- What is **not** done: no ads, no selling, no third-party analytics, no tracking.
- Optional features (future cloud sync) and their explicit consent model.
- User rights: export, backup, and **irreversible delete-all** ([08 F14](08-feature-specs.md)).
> Final legal wording is drafted with counsel; this spec defines intent and structure only. `[legal review]`

## 8. Permissions (Android)
Request the **minimum**, each justified and requested contextually:
| Permission | Why | When |
|---|---|---|
| Notifications | Opt-in reminders ([08 F13](08-feature-specs.md)) | Only if user enables reminders |
| Storage/SAF access | Backup/restore/export/import | Only at the moment of the action |
| (Future) Health Connect | Import wearable data | Only if user enables the integration |
| (Future) Microphone/Camera | Voice/image logging | Only if user enables those features |

No location, no contacts, no ad ID. `INTERNET` is **not** used by core flows; any future networked
feature declares and gates it explicitly ([NFR-9](02-requirements.md)).

## 9. Data Retention
- Data is retained **locally** until the user deletes it. We keep nothing server-side in v1 (there is
  no server).
- **Soft delete** (`is_deleted`) keeps entries recoverable via Undo and preserves sync history
  ([04 §2.1](04-database-design.md)); **hard delete** ("wipe all") is irreversible and clears keys ([04 §8](04-database-design.md)).
- Diagnostic logs are local-only, PII-free, and short-lived ([03 §5](03-architecture.md)).

## 10. Future Cloud Security (designed-for, opt-in, out of v1)
When optional cloud sync ships:
- **End-to-end encryption:** the server stores only ciphertext; encryption/decryption happen on-device;
  keys stay with the user. The provider (us) cannot read health data.
- Opt-in, revocable, with a clear consent screen and the ability to disable + purge cloud copies.
- Sync-ready schema already supports this without breaking migrations ([04 §10](04-database-design.md)).

---

## 11. Security in the Definition of Done
- No new dependency with ads/analytics/tracking (privacy gate, [10 §7](10-coding-standards.md)).
- No new network call in a core flow.
- Any new persisted field reviewed for sensitivity and encryption needs.
- Import paths validated; crypto only via vetted libraries.

---

*Next: [Phase 14 — Performance](14-performance.md).*
