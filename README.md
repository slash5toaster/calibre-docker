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
Assuming your library is at `/opt/Books`

### Apptainer

  Open the gui with:

```bash
apptainer run --cpus 4 \
  --bind /opt/Books/ \
  docker://slash5toaster/calibre:latest calibre
```

You can also run the web server with:

```bash
apptainer run \
  --bind /opt/Books/ \
  docker://slash5toaster/calibre:latest \
  calibre-server --port=8124 /opt/Books
```

### Docker/nerdCTL

Run the GUI with:

```bash
nerdctl run --rm -it \
        -v /opt/Books/:/opt/Books/ \
        -v $HOME/.config/calibre:/root/.config/calibre \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=$DISPLAY \
        slash5toaster/calibre:latest \
        calibre --with-library=/opt/Books/
```

To run the server:  

```bash
 nerdctl run --rm -it \
         -p 8124:8124 \
         -v /opt/Books/:/opt/Books/ \
         slash5toaster/calibre:latest \
         calibre-server --port=8124 /opt/Books/
 ```
