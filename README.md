# Calibre container

Docker and Apptainer https://apptainer.org/ recipes for the latest version of Calibre https://calibre-ebook.com/

Includes the calibre backup script https://github.com/slash5toaster/calibre_backups/ as a submodule.

Use `git clone --recurse-submodules git@github.com:slash5toaster/calibre-docker.git` to checkout.

If you didn't do a recursive clone,
run to get the submodules 
```bash
    for subm in $(grep submodule .gitmodules  | cut -d \" -f 2);
      do
        git submodule update --init $subm
      done
```

See https://github.com/slash5toaster/calibre_backups/#readme for usage

N.B.  The apptainer recipe requires Apptainer v1.2 or better
