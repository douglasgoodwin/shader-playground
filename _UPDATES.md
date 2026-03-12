# How to merge in changes from the original codebase

Below is the **common command‑line workflow** (GitHub, branch named `main`):

1. Add the original repository as `upstream` (one‑time setup):  
   ```bash
   git remote add upstream https://github.com/douglasgoodwin/shader-playground.git
   git fetch upstream
   ```
   This tells your local clone where to get changes from the source repository.[3][1]

2. Check out your fork’s default branch:  
   ```bash
   git checkout main
   ```
   You want to merge upstream’s default branch into the matching branch in your fork.[2][1]

3. Merge upstream changes into your local branch:  
   ```bash
   git merge upstream/main
   ```
   Or, if you prefer a fast‑forward only update:  
   ```bash
   git pull upstream main --ff-only
   ```
   This brings your local `main` in sync with the source repo.[4][1]

4. Push the updated branch back to your fork on GitHub:  
   ```bash
   git push origin main
   ```
   Now your fork’s `main` matches the original repo’s `main`.[5][1]

### Simple GitHub‑web method (no CLI)

If you just want to sync the fork’s default branch and you’re using GitHub:

- Go to your fork on GitHub.  
- Click the **Sync fork** / **Fetch upstream** button, then **Update branch** or **Fetch and merge**.[1][2]

This updates your fork’s branch directly from the source repository without using the terminal.[2][4]

### Quick comparison: CLI vs web

| Aspect            | Command line                              | GitHub web UI                           |
| ----------------- | ----------------------------------------- | --------------------------------------- |
| Setup needed      | Must add `upstream` remote manually [1]   | None after fork exists [2]              |
| Conflict handling | Full manual control in your editor [1][6] | Prompts you to open a PR to resolve [2] |
| Branch coverage   | Any branch you choose [1][4]              | Typically just default branch [2]       |
| Automation        | Scriptable, reusable commands [7][5]      | Manual clicks per update [2]            |

Do you usually work with this fork from the command line, or mainly through the GitHub web UI?

Sources
[1] How do I update or sync a forked repository on GitHub? https://stackoverflow.com/questions/7244321/how-do-i-update-or-sync-a-forked-repository-on-github
[2] Syncing a fork - GitHub Docs https://docs.github.com/articles/syncing-a-fork
[3] Fork a repository - GitHub Docs https://docs.github.com/articles/fork-a-repo
[4] Chapter 32 Get upstream changes for a fork https://happygitwithr.com/upstream-changes
[5] Keeping a fork up to date - gists · GitHub https://gist.github.com/CristinaSolana/1885435
[6] What's the process for updating a GitHub fork with new changes? https://community.latenode.com/t/whats-the-process-for-updating-a-github-fork-with-new-changes/17658
[7] How to rebase branch and sync forked repository with upstream ... https://kb.mautic.org/article/how-to-rebase-branch-and-sync-forked-repository-with-upstream-using-git.html
[8] Git Forks And Upstreams: How-to and a cool tip - Atlassian https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
[9] Updating branch of a fork with upstream changes : r/git - Reddit https://www.reddit.com/r/git/comments/ua1gfz/updating_branch_of_a_fork_with_upstream_changes/
[10] Forks - GitLab Docs https://docs.gitlab.com/user/project/repository/forking_workflow/
[11] git good with Chris! - real example: syncing a fork to upstream https://www.youtube.com/watch?v=_o-_MwBdS2E
[12] syncing forked repo with the original one : r/git - Reddit https://www.reddit.com/r/git/comments/18hpqpx/syncing_forked_repo_with_the_original_one/
[13] Keeping a fork updated : best practices ? : r/git - Reddit https://www.reddit.com/r/git/comments/z01ejf/keeping_a_fork_updated_best_practices/
[14] How to sync forked repo with upstream changes on GitHub https://community.latenode.com/t/how-to-sync-forked-repo-with-upstream-changes-on-github/36919
[15] Sync a forked repository on GitHub - YouTube https://www.youtube.com/watch?v=ZLrPRWHGY3k