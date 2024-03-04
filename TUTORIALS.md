# Panduan Penggunaan dvt

## Instalasi

Pastikan Anda memiliki Nix yang terpasang pada sistem Anda. Jika belum, ikuti perintah ini

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Instalasi tersebut diambil dari dokumentasi [`zero-to-nix`](https://zero-to-nix.com/start/install) dan bukan dari sumber [`nixos.org`](https://nixos.org/download.html) karena `zero-to-nix` sudah mengaktifkan flake sebagai bawaan dari instalasi Nix.

## Penggunaan Lingkungan Pengembangan

Lingkungan pengembangan yang tersedia, meliputi:

* [Go](#Go)
* [Nodejs](#Nodejs)
* [React Native](#React-Native)

### Go

```
nix develop github:eFishery/dvt\?dir=go
```

### Nodejs

```
nix develop github:eFishery/dvt\?dir=node
```

### React Native

```
nix develop github:eFishery/dvt\?dir=react-native
```

