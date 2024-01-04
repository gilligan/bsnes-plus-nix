{ system ? builtins.currentSystem
, pins ? import ./npins
, pkgs ? import pins.nixpkgs { inherit system; }
}:

let
  inherit (pkgs) stdenv lib;
  inherit (stdenv) mkDerivation;

  bsnessrc = pkgs.fetchFromGitHub {
    owner = "devinacker";
    repo = "bsnes-plus";
    rev = "000310841b9bc9c84b4beda12fa94d4e3c6691a3";
    sha256 = "sha256-Co1W2KJi78bz6uIPXt4GyTxRdUo9RPew8Gr7KxjkOeM=";
  };

  buildPlugin = name: mkDerivation rec {
    inherit name;
    version = "git";
    src = bsnessrc;
    sourceRoot = "${src.name}/${name}";
    buildInputs = with pkgs; [
      pkg-config
      qt5.qtbase
    ];
    enableParallelBuilding = true;
    installPhase = ''
      mkdir -p $out/lib
      cp lib${name}.so $out/lib
    '';
  };

  snesReader = buildPlugin "snesreader";
  snesFilter = buildPlugin "snesfilter";
  superGameboy = buildPlugin "supergameboy";
  snesMusic = buildPlugin "snesmusic";

in

mkDerivation rec {
  name = "bsnes-plus";
  version = "git";
  src = bsnessrc;

  patches = [ ./makefile.patch ];

  sourceRoot = "${src.name}/bsnes";
  enableParallelBuilding = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ./bsnes $out/bin
    mkdir -p $out/lib
    ln -s ${snesReader}/lib/libsnesreader.so $out/lib
    ln -s ${snesMusic}/lib/libsnesmusic.so $out/lib
    ln -s ${snesFilter}/lib/libsnesfilter.so $out/lib
    ln -s ${superGameboy}/lib/libsupergameboy.so $out/lib
  '';

  qtWrapperArgs = [
    "--set QT_QPA_PLATFORM xcb"
  ];

  buildInputs = with pkgs; [
    SDL.dev
    alsaLib
    dbus
    gdb
    libao
    libpulseaudio
    openal
    pkg-config
    qt5.qtbase
    qt5.qttools
    qt5.qtwayland
    qt5.wrapQtAppsHook
    udev
    xorg.libXv
    gnumake
    nixpkgs-fmt
  ];
}
