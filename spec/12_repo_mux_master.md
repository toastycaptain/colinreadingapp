# Repo Master — How to apply the Mux switch to THIS repo
Repo: https://github.com/toastycaptain/colinreadingapp citeturn2view0

This is the **execution order** to migrate the current AWS-based implementation to Mux.

---

## 1) Create Mux account + keys
In the Mux dashboard create:
- Access Token (ID + Secret)
- Signing Key (Key ID + Private Key)
- Webhook signing secret + webhook endpoint pointing to:
  - `https://<your-backend-domain>/webhooks/mux`

Add to `backend/.env`:
- `MUX_TOKEN_ID`
- `MUX_TOKEN_SECRET`
- `MUX_SIGNING_KEY_ID`
- `MUX_SIGNING_KEY_PRIVATE_KEY`
- `MUX_WEBHOOK_SIGNING_SECRET`

---

## 2) Patch backend first
Follow:
- `09_repo_mux_backend_patch.md`

Goal: backend can create direct upload URLs, accept webhook events, and issue playback session tokens.

---

## 3) Patch admin console
Follow:
- `10_repo_mux_admin_patch.md`

Goal: admins can upload a master video to Mux and see readiness.

---

## 4) Patch iOS app
Follow:
- `11_repo_mux_ios_patch.md`

Goal: iOS plays `https://stream.mux.com/<id>.m3u8?token=<jwt>` and no longer sets cookies.

---

## 5) Decommission AWS video infra (optional)
Once Mux is working end-to-end, you can:
- stop using the `infra/` video pipeline
- remove AWS video-related env vars and code
- keep AWS only for hosting DB/Redis/app, if you want

---

## 6) Final acceptance checks
- Upload → webhook → asset ready
- Parent adds book to child library
- Child plays and can only play/pause/back
- Playback denied if not in library or rights expired
