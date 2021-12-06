{ lib, python3Packages, qemu_test, qemu_pkg ? qemu_test, vde2, netpbm, coreutils, socat, enableOCR ? false, tesseract4, imagemagick_light, libtiff }:
let
  ocrProg = tesseract4.override { enableLanguages = [ "eng" ]; };
  imagemagick_tiff = imagemagick_light.override { inherit libtiff; };
in
with python3Packages;
buildPythonApplication rec {
  pname = "nixos-test-driver";
  version = "1.0";
  src = ./.;

  propagatedBuildInputs = [ colorama ptpython qemu_pkg vde2 netpbm coreutils socat ] ++ (lib.optionals enableOCR [ocrProg imagemagick_tiff]);

  doCheck = true;
  checkInputs = [ mypy pylint black ];
  checkPhase = ''
    mypy --disallow-untyped-defs \
          --no-implicit-optional \
          --ignore-missing-imports ${src}/test_driver
    pylint --errors-only ${src}/test_driver
    black --check --diff ${src}/test_driver
  '';
}
