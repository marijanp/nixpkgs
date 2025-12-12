{
  buildDunePackage,
  ppx_sexp_conv,
  base,
  async,
  async_kernel,
  async_unix,
  cohttp,
  conduit-async,
  core_unix ? null,
  uri,
  uri-sexp,
  logs,
  fmt,
  sexplib0,
  ipaddr,
  magic-mime,
  ounit,
  core,
  digestif,
}:

buildDunePackage {
  pname = "cohttp-async";

  inherit (cohttp)
    version
    src
    ;

  minimalOCamlVersion = "4.14";

  buildInputs = [ ppx_sexp_conv ];

  propagatedBuildInputs = [
    cohttp
    conduit-async
    async_kernel
    async_unix
    async
    base
    core_unix
    magic-mime
    logs
    fmt
    sexplib0
    uri
    uri-sexp
    ipaddr
  ];

  doCheck = true;
  checkInputs = [
    ounit
    core
    digestif
  ];

  meta = cohttp.meta // {
    description = "CoHTTP implementation for the Async concurrency library";
  };
}
