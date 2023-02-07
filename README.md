<div align="center">

<h1 id="toc">DVT - Development Tools</h1>
  <p>
  Development Tools and Templates 🛠️ ⚙️ 🔭 ❄️⛷️
  </p>

<p align="center">
  <a href="#overview"><strong>Overview</strong></a>  • 
  <a href="#usage"><strong>Usage</strong></a>  • 
  <a href="#contributions"><strong>Contributions</strong></a>
</p>

[![Built with Nix](https://github.com/nix-community/builtwithnix.org/raw/master/badge.svg)](https://builtwithnix.org)

</div>

## Overview

[[Back to the Table of Contents] ↑](#toc)

<!-- TODO -->

## Usage

[[Back to the Table of Contents] ↑](#toc)

In this section is require nix installed in your system, here steps to install: 

> you can **SKIP** this section when nix has been installed in your system and go use as [development environment](#as-development-environment), [project development environment](#as-project-development-environment), or [create new project with available template](#as-project-boilerplate).

* Install nix in your system
  * run command: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
  * OR [Read Here for more details](https://zero-to-nix.com/start/install#up)

### As Development Environment

* Select the _development environment_
  * run command: `nix develop github.com:efishery/dvt#<NAME>` - changes `<NAME>`.
  * example for _**node**_: `nix develop "github.com:efishery/dvt?dir=node"`
    * your local shell will be ready to use `nodejs@v18.x` , `yarn@1.22.x`, and `pnpm@7.x` with default shell is [Bash](https://www.gnu.org/software/bash/).
    * if you want to run with your default shell `nix develop "github.com:efishery/dvt?dir=node" -c $SHELL`

### As Project Development Environment

* Select the _development environment_ for your project:
  * run command: `nix flake -t github:efishery/dvt#<NAME>`
  * example for _**node**_: `nix flake init -t github:efishery/dvt#node`
    * in your project will contain all files from [node](./node).

<!-- TODO
### As Project Boilerplate

* Select availables project templates name in the tables.
  * run command `nix flake -t github:efishery/dvt#<NAME>`
  * example for _**react-native@0.71**_: `nix flake init -t github:efishery/dvt#rn71`
-->

## Contributions

[[Back to the Table of Contents] ↑](#toc)

<!-- TODO -->

### Request

## Acknowledgement

* [Nix](https://nixos.org)
* [dev-templates](https://github.com/the-nix-way/dev-templates)

[[Back to the Table of Contents] ↑](#toc)
