# Simulate the issue

Let's look at the size of the directory, including the `.git` database. Before things go wrong.

```log
mortimer@xpscold:git-testing (master)
└─ $ ▶ du -hcsb .
44,924 .
```

```sh
git checkout master
mkdir lotsoffiles
touch ./lotsoffiles/lotsoffiles-gen.sh
```

This is the `lotsoffiles-gen.sh` script:

```sh
#! /bin/bash
for n in {1..20}; do
  truncate -s 5K file$n.txt
done
## this is a big file that is not very compressable
wget https://chromedriver.storage.googleapis.com/93.0.4577.15/chromedriver_mac64.zip
```

Run the script to generate the files:

```sh
cd lotsoffiles
bash ./lotsoffiles-gen.sh
```

## Now lets create the mess in GitHub

```sh
git add .
git commit -m "big commit lots of files one big bad file"
git push
```

What is our disk size now?

```log
mortimer@xpscold:git-testing (master)
└─ $ ▶ du -hsb .
16,479,850        .
```

Ok, that big commit with lots of files that is hard to seperate has one big file we want gone and is now in master branch on the remote. How do we not only get rid of it, but ensure that the `.git` database is clean?

Oh no, wait, what has happened?

## Someone on another branch has pulled master and made some changes

```sh
git checkout working
git pull origin master
```

Some other files were added.

```sh
mkdir working
touch ./working/test.js
```

```sh
git add .
git commit -m "a working commit with the big bad file"
git push origin working
```

Someone pulled from master and kept working merrily on their branch. They made commits on top of the one we don't want and pushed to the remote.

## The last mistake

In an attempt to remove the big file, the user on master deletes the file and makes another commit. The big file is gone, but not from history.

```sh
git checkout master
git add .
git commit -m "reversing big file"
git push
```

But what is the size now?

```log
mortimer@xpscold:git-testing (master)
└─ $ ▶ du -hsb .
8,321,042 .
```

## Now the cleanup

```sh
git checkout master
git log
```

Find the last commit on master that we want:

```log
commit 777e7a7ecaef0dfef8f2cf919cca2681296304b0 (HEAD -> master
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:45:00 2021 +1000

    reversing big file

commit 431bd1123da15c597e496c413116919e0d9ae1bb
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:41:02 2021 +1000

    big commit lots of files one big bad file

commit 6b62247468340f8ec9ee61a2aee16bd5d43f038b
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:39:32 2021 +1000

    before things went wrong
```

Now lets reset the head back to that commit. Noting that before we go this, retain the files you actually want somewhere else on your machine. You'll need to recommit that work.

```sh
git reset --hard 6b62247468340f8ec9ee61a2aee16bd5d43f038b
git push -f
```

Great, now lets do the same for the working branch:

```sh
git checkout working
git log
```

Find the last commit on master that we want:

```log
commit a3e751174204b778e1f86228014d1bdb929d57c2 (HEAD -> workin
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:42:19 2021 +1000

    a working commit with the big bad file

commit 431bd1123da15c597e496c413116919e0d9ae1bb
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:41:02 2021 +1000

    big commit lots of files one big bad file

commit 6b62247468340f8ec9ee61a2aee16bd5d43f038b (origin/master,
Author: Christopher Mortimer <christopher@mortimer.xyz>
Date:   Thu Jul 29 21:39:32 2021 +1000

    before things went wrong
```

Noting that before we go this, retain the files and changes from the working commit you actually want somewhere else on your machine. You'll need to recommit that work.

```sh
git reset --hard 6b62247468340f8ec9ee61a2aee16bd5d43f038b
git push origin working -f
```

```log
mortimer@xpscold:git-testing (working)
└─ $ ▶ du -hsb .
8,218,212 .
```

## Is the git database clean?

Unfortunately we aren't free yet. The `.git/objects/pack` pack file is still huge (tracking the size of the big file).

```sh
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

Now we are back to a clean repo.

```log
mortimer@xpscold:git-testing (working)
└─ $ ▶ du -hsb .
40,916   .
```
