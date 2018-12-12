---
title: git提交步骤
tags: git
categories: BuildTools
---

`git add -A`

`git commit -a ""`

`git push origin HEAD:refs/for/master`

`export GIT_SSH_COMMAND='ssh -o KexAlgorithms=+diffie-hellman-group1-sha1'`

`scp -oKexAlgorithms=+diffie-hellman-group1-sha1  -p -P 29418 zhoufang@192.168.1.4:hooks/commit-msg .git/hooks/`