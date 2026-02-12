This is a clean, repeatable sequence you can follow to set up and run the project locally with everything installed in the project folder.

### 0. Setting up Node.js on macOS

If you don't have Node.js installed, use nvm (Node Version Manager):

**Install nvm:**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

**Configure your shell** by adding these lines to `~/.zshrc` (or `~/.bashrc` if using bash):

```bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

**Reload your shell and install Node:**

```bash
source ~/.zshrc
nvm install --lts
```

**If nvm installs the wrong versions**, reinstall with:

```bash
nvm install --reinstall-packages-from=node node
nvm current
npm -v
```

### 1. Download the source code

Option A – Git (recommended, though you will need to install `git`):

```sh
mkdir ~/_CODE ;
cd ~/_CODE ;
git clone https://github.com/douglasgoodwin/shader-playground.git ;
cd shader-playground
```

Option B – ZIP download:

1. Visit `https://github.com/douglasgoodwin/shader-playground` in a browser and download the ZIP.  
2. Unzip it somewhere under your home directory (for example `~/_CODE/shader-playground`).  
3. In Terminal:

```sh
cd ~/_CODE/shader-playground
```

Now `pwd` should end with `shader-playground`.

### 2. Install Node dependencies locally

From inside `shader-playground`:

```sh
npm install
```

- This reads `package.json` and `package-lock.json` and installs everything into `./node_modules` in this directory.[1][2]
- Nothing is installed globally; no admin access is needed.[3][4]

(If installation errors mention missing Node/npm, you need **some** Node in PATH—Herd, nvm, or lab setup—but it doesn’t matter which for this project.)


### 3. Run the dev server (Vite)

Still in `shader-playground`:

```sh
npm run dev
```

- This runs the `dev` script from `package.json`, which calls `vite` from `./node_modules/.bin`.[8][9]
- A URL often [http://localhost:5173/](http://localhost:5173/) will be printed; open it in your browser to see the shader playground.[8]

To stop the dev server, hit `Ctrl+C` in the terminal.

### 4. Run build and preview

Build a production bundle:

```sh
npm run build
```

Preview the built site locally:

```sh
npm run preview
```

These scripts call `vite build` and `vite preview` from the local `node_modules` as well.[10][11]

### 6. Run the linter

```sh
npm run lint
```

This runs `eslint src` using the local ESLint and the `eslint.config.js` you created.[9][5]

### 7. Verify everything is local to the project

From inside `shader-playground`:

```sh
npm root
ls node_modules/.bin | grep -E 'vite|eslint'
```

- `npm root` should print a path ending in `shader-playground/node_modules`.[12]
- The `ls` command should show `vite` and `eslint` in `node_modules/.bin`, confirming tools are installed only for this project.

If you like, run through these steps now and paste any command output that doesn’t match what you expect.

Sources
[1] Downloading and installing packages locally - npm Docs https://docs.npmjs.com/downloading-and-installing-packages-locally/
[2] package.json - npm Docs https://docs.npmjs.com/cli/v9/configuring-npm/package-json/
[3] Folders - npm Docs https://docs.npmjs.com/cli/v8/configuring-npm/folders
[4] npm install vs. npm ci | Baeldung on Ops https://www.baeldung.com/ops/npm-install-vs-npm-ci
[5] Configuration Files - ESLint - Pluggable JavaScript Linter https://eslint.org/docs/latest/use/configure/configuration-files
[6] Migrate to v9.x - ESLint - Pluggable JavaScript Linter https://eslint.org/docs/latest/use/migrate-to-9.0.0
[7] ESLint's new config system, Part 2: Introduction to flat config https://eslint.org/blog/2022/08/new-config-system-part-2/
[8] Getting Started - Vite https://vite.dev/guide/
[9] scripts - npm Docs https://docs.npmjs.com/cli/v8/using-npm/scripts/
[10] Deploying a Static Site - Vite https://vite.dev/guide/static-deploy
[11] Deploying a Static Site - Vite https://v2.vitejs.dev/guide/static-deploy
[12] Where does npm install packages? - Stack Overflow https://stackoverflow.com/questions/5926672/where-does-npm-install-packages
[13] shader-playground https://github.com/douglasgoodwin/shader-playground
