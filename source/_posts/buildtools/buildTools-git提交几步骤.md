---
title: git提交步骤
tags: git
categories: BuildTools
date: 2018/12/29
---

# Part 1 提交未授权问题

`git add -A`

`git commit -a ""`

`git push origin HEAD:refs/for/master`

`export GIT_SSH_COMMAND='ssh -o KexAlgorithms=+diffie-hellman-group1-sha1'`

`scp -oKexAlgorithms=+diffie-hellman-group1-sha1  -p -P 29418 zhoufang@192.168.1.4:hooks/commit-msg .git/hooks/`



# Part 2 无CHANGE-ID问题

```
remote: Hint: To automatically insert Change-Id, install the hook:
remote:   gitdir=$(git rev-parse --git-dir); scp -p -P 29418 zhoufaming@192.168.1.4:hooks/commit-msg ${gitdir}/hooks/
```

按照指令执行 `gitdir=$(git rev-parse --git-dir); scp -p -P 29418 zhoufaming@192.168.1.4:hooks/commit-msg ${gitdir}/hooks/`

然后重新commit，push即可。