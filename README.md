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
Assuming your library is at `$HOME/Calibre\ Library/`

### Apptainer

  Open the gui with:

```bash
apptainer run \
  --bind "$HOME/Calibre Library/" \
  docker://slash5toaster/calibre:latest calibre
```

You can also run the web server with:

```bash
apptainer run \
  --bind "$HOME/Calibre Library/" \
  docker://slash5toaster/calibre:latest \
  calibre-server --port=8124 /opt/Books
```

### Docker/nerdCTL

Run the GUI with:

```bash
nerdctl run --rm -it \
        -v "$HOME/Calibre Library/":"$HOME/Calibre Library/" \
        -v $HOME/.config/calibre:/root/.config/calibre \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=$DISPLAY \
        slash5toaster/calibre:latest \
        calibre --with-library="$HOME/Calibre Library/"
```

To run the server:

```bash
 nerdctl run --rm -it \
         -p 8124:8124 \
         -v "$HOME/Calibre Library/":"$HOME/Calibre Library/" \
         slash5toaster/calibre:latest \
         calibre-server --port=8124 "$HOME/Calibre Library/"
 ```

 There is an included docker compose template to run the server.  Please note you will *not* be able to run the server and the gui at the same time,
