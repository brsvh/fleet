{
  emacs,
  projectRoot,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "elfmt";
  version = "0.1.0";

  src = projectRoot + /tool/elfmt/elfmt.el;

  dontUnpack = true;

  nativeBuildInputs = [
    emacs
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/elfmt"
    patchShebangs --build "$out/bin/elfmt"

    runHook postInstall
  '';
}
