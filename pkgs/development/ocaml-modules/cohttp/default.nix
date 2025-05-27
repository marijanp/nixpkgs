{
  lib,
  fetchurl,
  buildDunePackage,
  ppx_sexp_conv,
  base64,
  http,
  logs,
  re,
  stringext,
  ipaddr,
  uri-sexp,
  fmt,
  alcotest,
}:

buildDunePackage (finalAttrs: {
  pname = "cohttp";
  version = "6.2.0";

  minimalOCamlVersion = "4.08";

  src = fetchurl {
    url = "https://github.com/mirage/ocaml-cohttp/releases/download/v${finalAttrs.version}/cohttp-${finalAttrs.version}.tbz";
    hash = "sha256-bwV1TK8z1rdeii4aISDKe1Ag4TiLwgJIRC0TOZNt3zs=";
  };

  buildInputs = [
    ppx_sexp_conv
  ];

  propagatedBuildInputs = [
    base64
    http
    ipaddr
    logs
    re
    stringext
    uri-sexp
  ];

  doCheck = true;
  checkInputs = [
    fmt
    alcotest
  ];

  meta = {
    description = "HTTP(S) library for Lwt, Async and Mirage";
    license = lib.licenses.isc;
    maintainers = [ lib.maintainers.vbgl ];
    homepage = "https://github.com/mirage/ocaml-cohttp";
  };
})
