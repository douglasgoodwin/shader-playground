## How to set a remote origin for a forked repository, and then how to merge in the latest changes from the remote into my repo



### Helpful tutorial: https://happygitwithr.com/upstream-changes



Set `origin` to point at *your* fork on GitHub, add the original repo as `upstream`, then fetch and merge from `upstream` into your local branch and push back to `origin`.

## 1. Set `origin` to your fork

In a local clone of the repo (in the project directory):

1. Check what remotes you currently have:
   ```bash
   git remote -v
   ```
2. If `origin` is missing or wrong, set it to your fork (HTTPS example):
   ```bash
   git remote set-url origin https://github.com/YOUR-USERNAME/YOUR-FORK.git
   ```
   Or, if there is no `origin` yet:
   ```bash
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-FORK.git
   ```
   You can use the SSH URL instead if that’s your usual setup.[3][4]
3. Verify:
   ```bash
   git remote -v
   ```
   You should see `origin` pointing at `YOUR-USERNAME/YOUR-FORK.git`.[1]

## 2. Add the original repo as `upstream`

1. Get the original repo URL from GitHub (the project you forked from).
2. Add it as `upstream`:
   ```bash
   git remote add upstream https://github.com/douglasgoodwin/shader-playground.git
   ```
3. Confirm:
   ```bash
   git remote -v
   ```
   You should now see both `origin` (your fork) and `upstream` (original).[5][1]

## 3. Merge latest changes from original into your fork

Typical flow assuming the default branch is `main`:

1. Fetch the latest from `upstream`:
   ```bash
   git fetch upstream
   ```
   This updates your local copy of `upstream/main` etc. without touching your working tree.[2][6]
2. Switch to your local `main`:
   ```bash
   git checkout main
   ```
3. Merge upstream’s `main` into your `main`:
   ```bash
   git merge upstream/main
   ```
   - If there are no conflicts, Git will auto-merge.
   - If there *are* conflicts, fix them in your editor, then:
     ```bash
     git add .
     git commit
     ```
     This step brings your local `main` up to date with the original project.[7][2]
4. Push the updated `main` to *your* fork:
   ```bash
   git push origin main
   ```
   Now your GitHub fork has the latest upstream changes.[8][2]

### Optional: using `rebase` instead of merge

If you prefer a linear history:

```bash
git fetch upstream
git checkout main
git rebase upstream/main
git push origin main
```

You may need `git push --force-with-lease origin main` if you’ve already pushed the old history.[9][10]



## Sources
[1] Configuring a remote repository for a fork - GitHub Docs https://docs.github.com/articles/configuring-a-remote-for-a-fork
[2] What's the process for updating a GitHub fork with new changes? https://community.latenode.com/t/whats-the-process-for-updating-a-github-fork-with-new-changes/17658
[3] git - How to change the fork that a repository is linked to https://stackoverflow.com/questions/11619593/how-to-change-the-fork-that-a-repository-is-linked-to
[4] How to Change Remote Origin in Git - KodeKloud https://kodekloud.com/blog/change-remote-origin-in-git/
[5] Adding an upstream remote to a forked Git repo - Graphite https://graphite.com/guides/upstream-remote
[6] Git commands to keep a fork up to date - Phil Nash https://philna.sh/blog/2018/08/21/git-commands-to-keep-a-fork-up-to-date/
[7] How to git fetch upstream https://graphite.com/guides/git-fetch-upstream
[8] How to move to a fork after cloning - GitHub https://gist.github.com/ElectricRCAircraftGuy/8ca9c04924ac11a50d48c2061d28b090
[9] How do I update or sync a forked repository on GitHub? https://stackoverflow.com/questions/7244321/how-do-i-update-or-sync-a-forked-repository-on-github
[10] Git Forks And Upstreams: How-to and a cool tip - Atlassian https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
[11] What the fork - How to switch to a fork after cloning a remote repository https://admcpr.com/what-the-fork/
[12] 2.5 Git Basics - Working with Remotes https://git-scm.com/book/ms/v2/Git-Basics-Working-with-Remotes
[13] Git remote repository tutorial and with set-url origin upstream ... https://www.youtube.com/watch?v=4AbJjvMHTZk
[14] What does 'git remote add upstream' help achieve? - Stack Overflow https://stackoverflow.com/questions/8948803/what-does-git-remote-add-upstream-help-achieve
[15] Chapter 32 Get upstream changes for a fork https://happygitwithr.com/upstream-changes