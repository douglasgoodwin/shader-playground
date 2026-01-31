# Installing on Windows

This guide covers setting up Node.js and running the project on Windows.

### 0. Setting up Node.js on Windows

If you don't have Node.js installed, use nvm-windows (Node Version Manager for Windows):

**Download and install nvm-windows:**

1. Go to https://github.com/coreybutler/nvm-windows/releases
2. Download `nvm-setup.exe` from the latest release
3. Run the installer (accept defaults)

**Open a new PowerShell or Command Prompt and install Node:**

```powershell
nvm list available
nvm install lts
nvm use lts
node -v
npm -v
```

### 1. Download the source code

Option A – Git (recommended):

```powershell
cd C:\Users\YourName\Code
git clone https://github.com/douglasgoodwin/shader-playground.git
cd shader-playground
```

Option B – ZIP download:

1. Visit `https://github.com/douglasgoodwin/shader-playground` in a browser and click "Code" → "Download ZIP"
2. Extract to a folder like `C:\Users\YourName\Code\shader-playground`
3. Open PowerShell or Command Prompt:

```powershell
cd C:\Users\YourName\Code\shader-playground
```

### 2. Install Node dependencies locally

From inside `shader-playground`:

```powershell
npm install
```

This reads `package.json` and installs everything into `.\node_modules` in this directory. Nothing is installed globally.

### 3. Run the dev server (Vite)

```powershell
npm run dev
```

A URL (typically http://localhost:5173/) will be printed. Open it in your browser to see the shader playground.

To stop the dev server, press `Ctrl+C` in the terminal.

### 4. Build and preview

Build a production bundle:

```powershell
npm run build
```

Preview the built site locally:

```powershell
npm run preview
```

### 5. Run the linter

```powershell
npm run lint
```

### Troubleshooting

**"nvm is not recognized"** – Close and reopen your terminal after installing nvm-windows.

**"node is not recognized"** – Run `nvm use lts` to activate the installed version.

**Permission errors** – Run PowerShell as Administrator, or use Command Prompt instead.
