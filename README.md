# PM Analysis Gallery

A lightweight, searchable gallery for sharing HTML analysis files across the team. Hosted on GitHub Pages — no infrastructure needed.

## Live Site

Once deployed: **https://YOUR_ORG.github.io/pm-analysis-gallery**

## Setup (one-time, ~10 minutes)

### 1. Create the GitHub repo

```bash
# From this folder:
cd pm-analysis-gallery
git init
git add .
git commit -m "Initial gallery setup"

# Create repo on GitHub (using GitHub CLI):
gh repo create YOUR_ORG/pm-analysis-gallery --private --source=. --push
```

> **Private vs Public:** Private repos can use GitHub Pages on GitHub Enterprise or with a paid plan. If your org is on free GitHub, you'll need a public repo or use GitHub Enterprise.

### 2. Enable GitHub Pages

1. Go to the repo on GitHub → **Settings** → **Pages**
2. Under "Source," select **Deploy from a branch**
3. Branch: `main`, Folder: `/ (root)`
4. Click **Save**
5. Your site will be live at `https://YOUR_ORG.github.io/pm-analysis-gallery` within a minute

### 3. Share the link

Send the gallery URL to the team. Anyone with repo access can view the hosted site.

## Adding an Analysis

### Option A: Use the helper script (recommended)

```bash
./add-analysis.sh ~/path/to/your-analysis.html
```

The script will prompt you for title, author, summary, and tags — then commit and push automatically.

### Option B: Manual steps

1. **Copy your HTML file** into the `analyses/` folder
2. **Edit `catalog.json`** — add an entry like this:

```json
{
  "title": "Your Analysis Title",
  "author": "Your Name",
  "date": "2026-04-01",
  "summary": "One or two sentences describing what this analysis covers.",
  "tags": ["PLG", "funnel", "Resolve"],
  "file": "analyses/your-filename.html"
}
```

3. **Commit and push:**

```bash
git add analyses/your-filename.html catalog.json
git commit -m "Add analysis: Your Analysis Title"
git push
```

The gallery updates automatically within ~1 minute of pushing.

## Adding a "Back to Gallery" link to your HTML files

Add this near the top of your HTML `<body>`:

```html
<a href="../index.html" style="color:#4361ee; text-decoration:none; font-size:0.9rem;">← Back to Gallery</a>
```

## Catalog Schema

Each entry in `catalog.json`:

| Field     | Type       | Required | Description                           |
|-----------|------------|----------|---------------------------------------|
| `title`   | string     | yes      | Display title of the analysis         |
| `author`  | string     | yes      | Who created it                        |
| `date`    | string     | yes      | ISO date (YYYY-MM-DD)                 |
| `summary` | string     | yes      | 1-2 sentence description              |
| `tags`    | string[]   | yes      | Category tags for filtering           |
| `file`    | string     | yes      | Relative path to the HTML file        |

## Repo Structure

```
pm-analysis-gallery/
├── index.html          ← Gallery UI (search, filter, browse)
├── catalog.json        ← Metadata registry for all analyses
├── analyses/           ← HTML analysis files
│   ├── example-1.html
│   └── ...
├── add-analysis.sh     ← Helper script for adding files
└── README.md           ← This file
```
