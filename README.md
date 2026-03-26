# Blue Lava Comunidade — Static GitHub Pages site

This repository is prepared to be published as a GitHub Pages user site at:

  https://bluelavacomunidade.github.io

Overview
- `index.html` — The landing page (root). Edit this for content and text.
- `style.css` — Main stylesheet (root). Mobile-first, simple to edit.
- `script.js` — Minimal JavaScript for navigation and smooth scrolling.
- `assets/` — Existing assets (images). Keep original site files in `bluelava-community/` if needed.
- `.nojekyll` — Included to ensure files starting with `_` are served.

Quick edits (beginner friendly)
- Change text: edit `index.html`. Headings and paragraphs are clearly labeled.
- Change hero image: replace `assets/images/hero-illustration.png` with your image (same filename and path), or update the `src` in `index.html`.
- Change logo: replace `assets/images/logo.png`.
- Update links: edit anchor `href` values in `index.html` (Join/Visit/Instagram placeholders currently set to `#`).

Publish on GitHub Pages
1. Create a repository named exactly `bluelavacomunidade.github.io` under your GitHub account `bluelavacomunidade`.
2. Push this project to that repository's `main` branch.
3. GitHub Pages will serve the files from the repository root. The site will be available at `https://bluelavacomunidade.github.io` shortly after push.

Notes & Tips
- This is a static site — no backend or framework. Keep edits simple.
- If you want a custom domain, add a `CNAME` file at the repo root with your domain.
- To preview locally, run a simple HTTP server (Python):

```bash
python3 -m http.server 8000
# then open http://localhost:8000 in your browser
```

If you want support customizing the design or updating links to the community channels, tell me which pages and I will update them.
