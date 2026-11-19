# guix-config — Polaris v9

`~/dotfiles/config-guix` for `don@polaris` — Tuxedo Polaris 17 — Stevensville, MI — GNU Guix System — Emacs 31.1.

One Org file builds the whole machine.

## Machine

- AMD Renoir + NVIDIA RTX 2060 Mobile — hybrid — `amdgpu` + `nvidia` — both visible
- 1920x1080@144Hz laptop + Samsung 32"@60Hz right — Mirror Off — XFCE + LightDM + X11 + LUKS
- Emacs 31.1 + wheatgrass + The Perfect Setup — Scheme 80.1% / Elisp 13.1% / Shell 6.8%
- Prompt `u@h w λ` — Menu key 135 → `Greek_lambda` — gammastep `42.015277:-86.505 5500:3500`

## Source

`config.org` is truth. It tangles:

- `config.scm` — System
- `home.scm` — Home — SSH agent `/run/user/1000/ssh-agent/socket` — GitHub `id_ed25519_github` — Brave Flatpak
- `init.el` — Emacs — Guix `home-files-service-type` `local-file "init.el"` → `~/.emacs.d/init.el` → `/gnu/store/...-init.el`

Edit `config.org` → `C-c C-v t` → `sudo guix system reconfigure` + `guix home reconfigure` → `cd ~/dotfiles/config-guix` → `git diff` clean.

Note: Emacs reads the store copy. Tangle alone is not enough — you must reconfigure for Emacs to see it.

## Does

**Sees.** Dual monitors declared in System, no xrandr scripts.

**Remembers.** OrgCube is Emacs extensibility and a new home for AI. It turns Emacs into the durable layer for AI tutorials, notes, and chat capture.

OrgCube v6 2026-11-05 → v9 2026-11-19 — 100% functional + restored + enhanced:

- `C-c o p` → `~/OrgCube/inbox/inbox.org` — inbox lives at root for prototype
- `C-c o e` → xelatex DejaVu → `PDF file produced.` clean — keeps inbox at root, moves pdf/tex/txt to `exports/`
- **Automating copy/paste for chatbox capture prototype — USER-COPY ONLY:**
    - `C-c o w` → START blackbox — `(interactive)` — 0.5s delay / 1s repeat
    - `C-c o W` → STOP blackbox — split from w, fixes `STARTED BLOCK=2` toggle bug
    - Captures every user COPY to `~/OrgCube/inbox/inbox.org` — 2082 lines → 12 lines / 250 bytes verified
    - Works with WhatsApp For Linux dropdown Copy — PRIMARY + CLIPBOARD + last-clip dedup
    - 150k cap prevents inbox-into-inbox flood
    - Guards: blocks `#+TITLE: OrgCube Inbox` and `% Created (% inbox.tex)` latex recursion
    - Fix: stale-buffer after `C-c o c` — now forces `revert-buffer` so disk == buffer
- Fixed in v6: lexical-binding col0, mv bug, Xmodmap load-file → shell-command, ox-latex truncation
- Fixed in v8.6.8: backups in `~/OrgCube/inbox/.bak/` — 139k / 127k verified — copied to `/home/don/AI_tutorials_text/Building_OrgCube/` then rm -rf .bak to keep tidy for future work
- Exports: `pandoc file.org -o file.pdf` + `chmod 444 *.pdf` → readable but not writable — opens in okular / evince — `*.org` stays 644 editable in Emacs

**Breathes.** `eye-relief.sh` gammastep — `flatpak/sync.sh` 10 apps — fixes `WEBKIT_DISABLE_DMABUF_RENDERER=1`.

**Fixes.** `00-fix-pulse-runtime.desktop` — `/run/user/1000` perms.

## Adjacent

`opendrs53now/docs` — GPL-3.0 — games that run here:

- `eigencube/` — v9 final `live.scm`
- `pong/` — v1 — eigencube v8.5.1 + raylib 5.5 + Guile — no submodules

OS here. Games next door. AI tutorials in `AI_tutorials_text/Building_OrgCube/` — pdf 444 readable.

## Layout

`config.org` → `config.scm` / `home.scm` / `init.el` + `channels.scm` + `my-packages/` + `orgcube/` + `Xmodmap` + `flatpak/` + `AI_tutorials_text/Building_OrgCube/`

Git repo is `~/dotfiles/config-guix/` — not `~/dotfiles/`.

77 commits — config.org Single Source of Truth — Updated 2026-11-19 — v9 Guix owns init.el — GPL-3.0