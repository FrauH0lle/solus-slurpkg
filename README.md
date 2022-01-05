# Poor man's Solus User Repository

**S**olus **L**ocal **U**ser **R**epository **PKG**. 

A collection of package definitions for [Solus](https://getsol.us/home/). Not
endorsed or supported by the Solus developers! Use on your own risk!

Please read through the whole README!

## Requirements and Installation

Clone this repository and make sure that `slurpkg` is in your `$PATH`.
Verify that the following dependencies are installed:

- `libxml2`
- `jq`

Follow the instructions in the [Solus help
center](https://getsol.us/articles/packaging) to setup `solbuild` and a local
repository. 

- Setting up `common` is not necessary here
- Use `sudo eopkg ar Solus
  https://mirrors.rit.edu/solus/packages/shannon/eopkg-index.xml.xz` to use the
  stable repository 

Create the file `/etc/solbuild/local-main-x86_64.profile` with following content

``` sh
#
# local-main-x86_64 configuration
#
# Build Solus packages using the main repository image.

image = "main-x86_64"

# If you have a local repo providing packages that exist in the main
# repository already, you should remove the repo, and re-add it *after*
# your local repository:
remove_repos = ['Solus']
add_repos = ['Local','Solus']

# A local repo with automatic indexing
[repo.Local]
uri = "/var/lib/solbuild/local"
local = true
autoindex = true

# Re-add the Solus stable repo
[repo.Solus]
uri = "https://mirrors.rit.edu/solus/packages/shannon/eopkg-index.xml.xz"
```

## Usage and Description

Use `slurpkg help` to view an overview of available commands and what they are
supposed to do.

### `slurpkg add`

Basically, this command creates a symlink for a package from the `packages`
directory to the `build` directory.

- You can add multiple packages at once
- You can pass a file with the `--file` option. The file should have one package
  per line, comments allowed:
  
  ``` conf
  # This is a comment
  package1
  # This is a 
  # multiline comment
  package2
  package3
  ```
  
- Will check the `req_patches` directory for the presence of patches and link
  them into patches

### `slurpkg build`

Build packages and moves them into the local repository.

- Accepts multiple `/path/to/package`s
- If no arguments are given (default), it will build all packages found in the
  `build` directory
  
### `slurpkg kmodules`

Rebuild kernel modules from slurpkg, if necessary.

### `slurpkg patches`

Inspired from [Portage's
patches](https://wiki.gentoo.org/wiki//etc/portage/patches) functionality. Will
look for patches in the `patches` directory and try to apply them to a Solus
package repository. 

- Each subfolder in `patches` has to have the exact name as the Solus package
  repository. Check https://dev.getsol.us to find them.
- There should be only one `.patch` file with the same name as the Solus package
  repository. For example:
  
  ```
  patches/
    - emacs/
      - emacs.patch
  ```
  
In order to create a patch, you need to clone the Solus package repository, make
your changes and generate a patch from these. For example via:

``` sh
git add .
git diff --cached > package_name.patch
```
  
Then copy `package_name.patch` into to appropriate folder.

### `slurpkg update`

Maybe the most useful command. Update `slurpkg` itself, the (re)build the
packages, apply all patches, upgrade the system and rebuild kernel modules. 

## Details

- Main entry point is the `slurpkg` script
- Subcommands should be in their respective `slurpkg-*` files
- `libslurpkg` should contain functions which can be used by all scripts

### `slurpkg.json` 

This is a simple `JSON` database which serves the following purposes:

- Define which package is also a kernel module. For example:

  ``` json
  {
    "name": "xpadneo",
    "kernel_module": "true",
    "kernel_module_file": "hid-xpadneo.ko"
  }
  ```

This means, that `xpadneo` is a kernel module and `hid-xpadneo.ko` is the kernel
module file. The file will be used to determine if a kernel module is present
for a kernel and if not, will trigger the rebuild. Even if a kernel module
package has multiple kernel module files, `kernel_module_file` should contain
only one.

- Define dependencies which are not available in the main Solus repository but
  only here. For example:
  
  ```json
  {
    "name": "package",
    "dependencies": [
        "dep1",
        "dep2"
      ]
    }
  ```

This means, that when `package` gets added, the dependencies will also get
added. Furthermore, `slurpkg` will build these dependencies before `package`
itself is built.

### Folders

- `build` Should be empty on the remote, contains the symlinks to `packages`
- `local` Host specific packages. Should be empty on the remote, `packages` here
  take precendenc over `packages`
- `patches` Should be empty on the remote, contains the patches created by the
  user 
- `req_patches` Required patches. Contains required patches for some packages.
  Use carefully.
- `scripts` Little helper scripts
- `unmaintained` Package definitions which are not maintained and kept for
  reference or the future

### Folders and files in the $HOME directory

- `$HOME/.cache/slurpkg` Cache, contains the repositories which should get
  patched 
- `$HOME/.local/share/slurpkg` Contains `slurpkg-db.json`
- `slurpkg-db.json` Local database, contains information about the patched
  packages (version, commits, etc), built packages (names, subpackages) and
  built kernel modules
  
## Limitations, Caveats and Scope

First of all and like stated above: You will use this on you own risk! This
means that I do not guarantee that `slurpkg` will do no harm to your system, nor
that any resulting package will. So far, it is made in a *works-on-my-machine*
way.

An obvious comparison is with the [AUR](https://aur.archlinux.org) and AUR
helpers like [yay](https://github.com/Jguer/yay) and
[paru](https://github.com/Morganamilo/paru). And too make it short: `slurpkg` is
by far not as powerful as the aforementioned helpers! For example, `slurpkg`
does not install a package. It builds them only and makes a local repository
available. That's it. Installation needs to be done by the user. Furthermore,
these helpers contain sophisticated functionalities (like dependency resolution)
whereas `slurpkg` is made in a naive and simple way. 

Regarding the patching process: This is also not as powerful and easy to use as
Gentoo's implementation. On drawback is that we need to patch the original
`package.yml`. Thus, the more complex the patch is, the higher is the chance
that it will break when Solus updates a package. A good example is the following
situation: You want to have the [TKG
kernel](https://github.com/Frogging-Family/linux-tkg). 

Option 1: 

You create your own `linux-tkg` package, which is based on the `linux-current`
package. The advantage here is that you can update it when you want it and
target the kernel release you want. The disadvantage is, that you also need to
provide all kernel modules, for example you need to have a `virtualbox-tkg`
package. Now you need to maintain two packages, and so on.

Option 2:

You create a patch for `linux-current` which contains the modifications from the
TKG kernel. The advantage is that you do not need to take care of the kernel
modules, as they are still compatible. The disadvantage is that you still need
to maintain the patch and anticipate kernel updates from Solus, especially when
the major version changes. 
