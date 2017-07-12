---
layout: post
title: Using private git repositories with Google Repo
date: 2017-07-12 14:37:00
categories: miscellaneous
tags: [repo, github, gitlab, private repository]
---

Make sure you have SSH keys for Github (or Gitlab) setup so that you can do this from a command line

    git clone git@github.com:scottellis/private-repo.git

Then your [Google Repo][repo] manifest xml can have a **remote** entry for the private repository that looks like this.

    <?xml version="1.0" encoding="UTF-8"?>
    <manifest>
      <remote  name="github-public" fetch="git://github.com"/>
      <remote  name="github-private" fetch="ssh://git@github.com"/>
      <project name="scottellis/tspress" remote="github-public" revision="master"/>
      <project name="scottellis/zmon" remote="github-private" revision="master"/>      
    </manifest>


[repo]: https://gerrit.googlesource.com/git-repo/