These steps will help you download, install, and run the shader-playground project on your own computer. The process is mostly the same on macOS and Windows: install Node.js, download the project, install its dependencies, and start the local development server. Once the server is running, you can open the project in your browser and begin working locally.

## First, **install Node.js** if you do not already have it.

### On macOS, one good option is nvm:

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

### Then **add this to your ~/.zshrc**:

```
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### Reload your shell and **install Node**:

```
source ~/.zshrc
nvm install --lts
```

On Windows, install Node.js from the official Node.js website using the standard installer. After installation, open PowerShell or Command Prompt and make sure these work:

```
node -v
npm -v
```

## Next, **download the project code**.



### Option 1: Download with Git



#### On macOS or Linux:

```
mkdir -p ~/_CODE
cd ~/_CODE
git clone https://github.com/douglasgoodwin/shader-playground.git
cd shader-playground
```

#### On Windows PowerShell:

```
mkdir $HOME\_CODE
cd $HOME\_CODE
git clone https://github.com/douglasgoodwin/shader-playground.git
cd shader-playground
```

### Option 2: Download the ZIP

Go to the project page on GitHub and download the ZIP file. Unzip it somewhere convenient, then open a terminal in the unzipped shader-playground folder.



### For example:

#### On macOS:

- unzip into something like ~/_CODE/shader-playground
- then in Terminal:

```
cd ~/_CODE/shader-playground
```

#### On Windows:

- unzip into something like C:\Users\YourName\_CODE\shader-playground
- then in PowerShell:

```
cd $HOME\_CODE\shader-playground
```

### Once you are inside the shader-playground folder, install the dependencies:

```
npm install
```

### Then start the local development server:

```
npm run dev
```

## Open the local URL shown in the terminal, usually:

```
http://localhost:5173/
```

To stop the server later, press Ctrl+C.


## Here is the short version:

1. Install Node.js.
2. Download or clone shader-playground.
3. Open a terminal in that folder.
4. Run:

```
npm install
npm run dev
```



1. Open the local URL printed in the terminal.


**Sources**
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
