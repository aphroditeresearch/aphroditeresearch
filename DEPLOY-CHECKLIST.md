# DEPLOY TO VERCEL VIA GITHUB — Fresh Repo

You deleted the old repos. This is a clean start. ~10 minutes, no command line.

## 1. Put the files in a new GitHub repo
1. github.com → **New repository** → name it `aphrodite-research` → Create.
2. On the empty repo page: **Add file → Upload files**.
3. Drag in **everything** from this folder — all the `.html` files, `vercel.json`,
   `README.md`, and the `assets/`, `docs/`, and `legal/` folders.
   - Make sure `index.html` sits at the **top level** of the repo (not inside a subfolder),
     or the gate won't load as the landing page.
4. Scroll down → **Commit changes**.

## 2. Connect Vercel
1. vercel.com → **Sign Up / Log in** → continue **with GitHub** (one click).
2. **Add New… → Project → Import** your `aphrodite-research` repo.
3. Leave build settings at defaults (it's a static site — no build command,
   no output directory to set).
4. **Deploy.** ~1 minute later you get a live URL like `aphrodite-research.vercel.app`.

## 3. From now on
Any change you commit to GitHub auto-redeploys within ~1 minute.

## 4. After deploy — click through to confirm
- Gate loads (`index.html`) → **Enter the Archive** → homepage
- Homepage → **Explore the Archive** → archive
- Archive → a compound card (Retatrutide / GHK-Cu)
- On GHK-Cu: check the evidence-by-outcome table, Route Integrity warning, Claim Gap
- Compound → **Cross the Threshold** → deep-dive
- **Membership** → pricing → **Become an Initiate** → sign-in page
- Footer legal links open the legal pages

If any link 404s, the files landed in a subfolder — re-upload so the `.html` files
sit at the repo root.

## Custom domain (optional, later)
Buy a domain (Namecheap, etc.) → in Vercel, Project → **Settings → Domains → Add** →
follow the DNS steps.

## Still true
The paywall is a visual demo — no login/payment yet. Fine to share and show people;
don't collect money until the membership backend exists (`docs/MEMBERSHIP-SPEC.md`).
