{
  lib,
  stdenv,
  ocaml,
  findlib,
  dune_2,
  dune_3,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;
  excludeDrvArgNames = [
    "minimalOCamlVersion"
    "duneVersion"
    "separateDebugMetadata"
    "disableOCamlDebugInfo"
    "disallowOCamlCompilerReferences"
    "ocamlCompilerReferenceOutputs"
    "ocamlCompilerReferenceTargets"
  ];
  extendDrvArgs =
    finalAttrs:
    {
      pname,
      version,
      nativeBuildInputs ? [ ],
      enableParallelBuilding ? true,
      separateDebugMetadata ? true,
      disableOCamlDebugInfo ? false,
      disallowOCamlCompilerReferences ? false,
      ocamlCompilerReferenceOutputs ? [
        "bin"
        "lib"
        "out"
      ],
      ocamlCompilerReferenceTargets ? [ ocaml ],
      ...
    }@args:

    let
      Dune =
        let
          dune-version = args.duneVersion or "3";
        in
        {
          "1" = throw "Support for dune version 1 has been removed";
          "2" = dune_2;
          "3" = dune_3;
        }
        ."${dune-version}";
      explicitOutputs = args.outputs or [ "out" ];
      addsDevOutput = separateDebugMetadata && !(builtins.elem "dev" explicitOutputs);
      finalOutputs = lib.unique (explicitOutputs ++ lib.optional separateDebugMetadata "dev");
      checkedOCamlReferenceOutputs = builtins.filter (
        output: builtins.elem output finalOutputs
      ) ocamlCompilerReferenceOutputs;
      ocamlCompilerReferenceChecks = lib.genAttrs checkedOCamlReferenceOutputs (output: {
        disallowedReferences =
          (args.outputChecks.${output}.disallowedReferences or [ ]) ++ ocamlCompilerReferenceTargets;
      });
    in

    if args ? minimalOCamlVersion && lib.versionOlder ocaml.version args.minimalOCamlVersion then
      throw "${pname}-${version} is not available for OCaml ${ocaml.version}"
    else
      ({
        name = "ocaml${ocaml.version}-${pname}-${version}";

        strictDeps = true;

        inherit enableParallelBuilding;
        outputs = finalOutputs;
        dontAddStaticConfigureFlags = true;
        configurePlatforms = [ ];
        setOutputFlags = args.setOutputFlags or (!addsDevOutput);
        moveToDev = args.moveToDev or (!addsDevOutput);

        nativeBuildInputs = [
          ocaml
          Dune
          findlib
        ]
        ++ nativeBuildInputs;

        buildPhase =
          args.buildPhase or ''
            runHook preBuild
            dune build -p ${pname} ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}
            runHook postBuild
          '';

        installPhase =
          args.installPhase or ''
            runHook preInstall
            dune install --prefix $out --libdir $OCAMLFIND_DESTDIR ${pname} \
             ${
               if lib.versionAtLeast Dune.version "2.9" then
                 "--docdir $out/share/doc --mandir $out/share/man"
               else
                 ""
             }
            runHook postInstall
          '';

        preFixup =
          (args.preFixup or "")
          + lib.optionalString separateDebugMetadata ''
            for outputName in $(getAllOutputNames); do
              mkdir -p "''${!outputName}"
            done
            for outputName in $(getAllOutputNames); do
              outputPath="''${!outputName}"
              if [ "$outputPath" = "$dev" ] || [ ! -e "$outputPath" ]; then
                continue
              fi

              find "$outputPath" -type f \( -name '*.cmt' -o -name '*.cmti' \) -print0 \
                | while IFS= read -r -d "" file; do
                  relativePath="''${file#$outputPath/}"
                  target="$dev/$relativePath"
                  mkdir -p "$(dirname "$target")"
                  mv "$file" "$target"
                done
            done
          '';

        checkPhase =
          args.checkPhase or ''
            runHook preCheck
            dune runtest -p ${pname} ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}
            runHook postCheck
          '';

        meta = (args.meta or { }) // {
          platforms = args.meta.platforms or ocaml.meta.platforms;
        };
      }
      // lib.optionalAttrs disallowOCamlCompilerReferences {
        __structuredAttrs = true;
        outputChecks = lib.recursiveUpdate (args.outputChecks or { }) ocamlCompilerReferenceChecks;
      }
      // lib.optionalAttrs (disableOCamlDebugInfo && !(args ? OCAMLPARAM)) {
        OCAMLPARAM = "_,g=0";
      });
}
