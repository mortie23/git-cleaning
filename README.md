# Simulate the issue

```sh
git checkout master
mkdir lotsoffiles
touch ./lotsoffiles/lotsoffiles-gen.sh
```

Put this in the file gernation script

```sh
#! /bin/bash
for n in {1..20}; do
  truncate -s 5K file$n.txt
done
## this is a big file that is not very compressable
wget https://chromedriver.storage.googleapis.com/93.0.4577.15/chromedriver_mac64.zip
```

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

Ok, that big commit with lots of files that is hard to seperate has one big file we want gone and is now in master branch on the remote. How do we not only get rid of it, but ensure that the `.git` database is clean?

Oh no, wait, what has happened?

## Someone on another branch has pulled master and made some changes

```sh
git checkout working
git pull origin master
```

Some other files added and modified.

```sh
mkdir working
touch ./working/test.js
```

```sh
git add .
git commit -m "a working commit with the big bad file"
git push origin working
```

Someone pulled from master and kept working merrily ontheir branch. They made commits on top of the one we don't want and pushed to the remote.

## The last mistake

To attempt to remove the big file, the user on master deletes the file and makes another commit. The big file is gone, but not from history.

```sh
git checkout master
git add .
git commit -m "reversing big file"
git push
```

## Now the cleanup

```sh
git checkout master
git log
```

Find the last commit on master that we want:

![]()

Now lets reset the head back to that commit.

```sh
git reset --hard 61d040c19413a6e0db4f568808a200bf2141694a
git push -f
```

Great, now lets do the same for the working branch:

```sh
git checkout working
git log
```

Find the last commit on master that we want:

![]()

```sh
git reset --hard 489a9fce4dbcb9dec78653873a2c950c5ae6ff7c
git push origin working -f
```

## is the git database clean?

Unfortunately we aren't free yet. The `.git/objects/pack` pack file is still huge (tracking the size of the big file).

```sh
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```
