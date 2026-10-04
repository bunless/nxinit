{
  lib,
  stdenv,
  hareHook,
  writableTmpDirAsHomeHook,
}:

stdenv.mkDerivation {
  pname = "nxinit";
  version = "0.1.0";

  src = lib.cleanSource ../.;

  nativeBuildInputs = [
    hareHook
    writableTmpDirAsHomeHook
  ];

  buildPhase = ''
    runHook preBuild
    hare build -o nxinit ./src
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 nxinit "$out/bin/nxinit"
    runHook postInstall
  '';

  meta = {
    description = "A minimal init system for Linux";
    mainProgram = "nxinit";
    platforms = lib.platforms.linux;
  };
}
