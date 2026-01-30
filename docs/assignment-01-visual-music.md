# Assignment 1: Visual Music Research & Local Setup

**Due:** Before next class
**Points:** 10

---

## Part 1: Set Up Your Local Development Environment (4 points)

Follow these instructions to get the shaders running in local web pages. You don't need Claude to try the exercises.

### 1. Download the source code

**Option A** – Git (recommended, though you will need to install git):

**> [How to install git](https://github.com/git-guides/install-git)**

```
mkdir ~/_CODE ;
cd ~/_CODE ;
git clone https://github.com/douglasgoodwin/shader-playground.git ;
cd shader-playground
```

**Option B** – ZIP download (this will work if you don't have git)

Visit https://github.com/douglasgoodwin/shader-playground in a browser and download the ZIP.
Unzip it somewhere under your home directory (for example ~/_CODE/shader-playground).
In Terminal:

```
cd ~/_CODE/shader-playground
```

Now pwd should end with shader-playground.

### 2. Install Node dependencies locally

From inside shader-playground:

`npm install`

This reads package.json and package-lock.json and installs everything into ./node_modulesin this directory.[1][2]
Nothing is installed globally; no admin access is needed.[3][4]
(If installation errors mention missing Node/npm, you need some Node in PATH—Herd, nvm, or lab setup—but it doesn’t matter which for this project.)

### 3. Run the dev server (Vite)

Still in shader-playground:

`npm run dev`

This runs the dev script from package.json, which calls vite from ./node_modules/.bin.[8][9]
A URL often `http://localhost:5173/` will be printed; open it in your browser to see the shader playground.[8]
To stop the dev server, hit Ctrl+C in the terminal.

### 4. Edit the shader file

Use vscode or your text editor to make changes to the first exercise.

Make changes, save the file, and watch your screen change colors. 

Here is the path to the file--edit it with VSCode or Textedit or your text editor of choice:

`shader-playground/src/shaders/exercises/ex1-1-color-mixing.glsl`

**What to submit:** A screenshot showing the shader playground running in your browser with the URL visible.

---

## Part 2: Visual Music Research (5 points)

Explore the world of visual music—the genre of experimental film that uses animation, abstract imagery, and motion synchronized to (or evoking) musical structures.

### Artists to explore:

- **John Whitney** — Catalog, Permutations, Arabesque, Matrix, Lapis
- **James Whitney** — Lapis, Yantra, Wu Ming
- **Mary Ellen Bute** — Rhythm in Light, Synchromy, Mood Contrasts
- **Len Lye** — A Colour Box, Free Radicals, Particles in Space
- **Jordan Belson** — Allures, Samadhi, Chakra
- **Oskar Fischinger** — Komposition in Blau, An Optical Poem, Motion Painting No. 1
- **Norman McLaren** — Dots, Loops, Synchromy
- **Lillian Schwartz** — Pixillation, UFOs, Metamorphosis

### Where to look:

- YouTube (search artist names + "visual music" or film titles)
- Vimeo
- [Center for Visual Music](http://www.centerforvisualmusic.org/)
- UbuWeb (ubu.com)

### What to do:

1. **Watch at least 3 different pieces** by different artists (spend at least 30 minutes total)

2. **Take notes** on each piece:
   - Title and artist
   - What shapes, patterns, or movements do you see?
   - How would you describe the motion? (pulsing, spiraling, oscillating, flowing, etc.)
   - What's the relationship between the visuals and any sound/music?
   - What draws your attention? What's surprising or beautiful?

3. **Choose one piece (or a specific moment from a piece)** that you'd like to try to replicate with shader code

### What to submit:

A short written response (200-400 words) that includes:

1. **Brief notes** on the 3+ pieces you watched
2. **Your chosen piece** — which one do you want to replicate?
3. **Description** — How would you describe it to someone (or to Claude) who hasn't seen it? Be specific about:
   - The shapes involved
   - How they move
   - How they're arranged (grid, spiral, random, etc.)
   - Color and how it changes
   - Any patterns or rhythms you notice

Think of this description as practice for talking to AI about what you want to create. The more precisely you can describe visual phenomena, the better results you'll get.



---

## Tips

- Message me if you get stuck on setup, check the tutorial video (posted separately) or 
- Don't overthink the description—just try to capture what you see as clearly as possible
- There's no wrong answer for which piece to choose; pick something that excites you
- Consider: what looks achievable vs. what looks impossibly complex? We'll tackle both eventually
