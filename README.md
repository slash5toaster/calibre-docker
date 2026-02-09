# Calibre container

Docker and Apptainer <https://apptainer.org/> recipes for the latest version of Calibre <https://calibre-ebook.com/>

Includes the calibre backup script <https://github.com/slash5toaster/calibre_backups/> as a submodule.

Use `git clone --recurse-submodules https://github.com/slash5toaster/calibre-docker.git` to checkout.

If you didn't do a recursive clone,
run this bash snippet to get the submodules,

```bash
    for subm in $(grep submodule .gitmodules  | cut -d \" -f 2);
      do
        git submodule update --init $subm
      done
```

See <https://github.com/slash5toaster/calibre_backups/#readme> for usage

N.B.  The apptainer recipe requires Apptainer v1.2 or better

## Usage

To run the container, you'll need to bind your library into the container.

### Apptainer

  Open the gui with:

  ```bash
  apptainer run --cpus 4 --bind /opt/Books/ docker://slash5toaster/calibre:latest calibre
  ```

You can also run the web server with:

### Docker/nerdCTL

 It's easiest to run the server with:

 ```bash
 nerdctl run --rm -it \
         -p 8124:8124 \
         -v /opt/Books/:/opt/Books/ \
         slash5toaster/calibre:9.2.1 \
         calibre-server --port=8124 /opt/Book
 ```
