# SPDX-FileCopyrightText: 2020 TQ Tezos
# SPDX-License-Identifier: LicenseRef-MIT-TQ

# This file is derived from
# https://gitlab.com/morley-framework/morley/-/blob/99426dc89cf8c03eaeae4d62cbe67a0c008b60fc/ci.nix
# and thus is more complicated than necessary (supports a list of packages).
# Currently we don't care about that.

rec {
  sources = import ./nix/sources.nix;
  xrefcheck = import sources.xrefcheck;
  haskell-nix = import sources."haskell.nix" {
    sourcesOverride = { hackage = sources."hackage.nix"; stackage = sources."stackage.nix"; };
  };
  pkgs = import sources.nixpkgs haskell-nix.nixpkgsArgs;
  weeder-hacks = import sources.haskell-nix-weeder { inherit pkgs; };
  tezos-client = (import "${sources.tezos-packaging}/nix/build/pkgs.nix" {}).ocamlPackages.tezos-client;
  ligo = (import "${sources.ligo}/nix" {}).ligo-bin;

  # all local packages and their subdirectories
  # we need to know subdirectories to make weeder stuff work
  local-packages = [
    { name = "baseDAO"; subdirectory = "."; }
    { name = "baseDAO-ligo-meta"; subdirectory = "./ligo/haskell"; }
    { name = "templateDAO"; subdirectory = "./template"; }
  ];

  # names of all local packages
  local-packages-names = map (p: p.name) local-packages;

  # haskell.nix package set
  # parameters:
  # - release – 'true' for "release" (e. g. master) build,
  #   'false' for "development" (e. g. PR) build.
  # - commitSha, commitDate – git revision info used for contract documentation.
  hs-pkgs = { release, commitSha ? null, commitDate ? null }: pkgs.haskell-nix.stackProject {
    src = pkgs.haskell-nix.haskellLib.cleanGit { src = ./.; };

    modules = [
      {
        # common options for all local packages:
        packages = pkgs.lib.genAttrs local-packages-names (packageName: {
          package.ghcOptions = with pkgs.lib; concatStringsSep " " (
            ["-O0" "-Werror"]
            # produce *.dump-hi files, required for weeder:
            ++ optionals (!release) ["-ddump-to-file" "-ddump-hi"]
          );

          # enable haddock for local packages
          doHaddock = true;

          # in non-release mode collect all *.dump-hi files (required for weeder)
          postInstall = if release then null else weeder-hacks.collect-dump-hi-files;
        });

        # disable haddock for dependencies
        doHaddock = false;
      }

      # provide commit sha and date for tezos-nbit in release mode:
      {
        packages.baseDAO = {
          preBuild = ''
            export MORLEY_DOC_GIT_COMMIT_SHA=${if release then pkgs.lib.escapeShellArg commitSha else "UNSPECIFIED"}
            export MORLEY_DOC_GIT_COMMIT_DATE=${if release then pkgs.lib.escapeShellArg commitDate else "UNSPECIFIED"}
          '';
        };
        packages.baseDAO-ligo-meta = {
          preBuild = ''
            mkdir -p ./ligo/haskell/test
            cp ${build-ligo} ./ligo/haskell/test/baseDAO.tz
            cp ${build-ligo-registryDAO-storage} ./ligo/haskell/test/registryDAO_storage.tz
          '';
        };
      }
    ];
  };

  hs-pkgs-development = hs-pkgs { release = false; };

  # component set for all local packages like this:
  # { baseDAO = { library = ...; exes = {...}; tests = {...}; ... };
  #   ...
  # }
  packages = pkgs.lib.genAttrs local-packages-names (packageName: hs-pkgs-development."${packageName}".components);

  # returns a list of all components (library + exes + tests + benchmarks) for a package
  get-package-components = pkg: with pkgs.lib;
    optional (pkg ? library) pkg.library
    ++ attrValues pkg.exes
    ++ attrValues pkg.tests
    ++ attrValues pkg.benchmarks;

  # per-package list of components
  components = pkgs.lib.mapAttrs (pkgName: pkg: get-package-components pkg) packages;

  # a list of all components from all packages in the project
  all-components = with pkgs.lib; flatten (attrValues components);

  # build haddock
  haddock = with pkgs.lib; flatten (attrValues
    (mapAttrs (pkgName: pkg: optional (pkg ? library) pkg.library.haddock) packages));

  # run baseDAO to produce contract documents
  contracts-doc = { release, commitSha ? null, commitDate ? null }@releaseArgs:
    pkgs.runCommand "contracts-doc" {
      buildInputs = [ (hs-pkgs releaseArgs).baseDAO.components.exes.baseDAO ];
    } ''
      mkdir $out
      cd $out
      baseDAO document --name TrivialDAO --output TrivialDAO.md
      baseDAO document --name RegistryDAO --output RegistryDAO.md
      baseDAO document --name TreasuryDAO --output TreasuryDAO.md
      baseDAO document --name GameDAO --output GameDAO.md
    '';

  build-ligo = pkgs.stdenv.mkDerivation {
    name = "baseDAO-ligo";
    src = ./ligo;
    nativeBuildInputs = [ ligo ];
    buildPhase = "make";
    installPhase = "cp out/baseDAO.tz $out";
  };

  build-ligo-registryDAO-storage = pkgs.stdenv.mkDerivation {
    name = "baseDAO-ligo";
    src = ./ligo;
    nativeBuildInputs = [ ligo ];
    buildPhase = "make";
    installPhase = "cp out/registryDAO_storage.tz $out";
  };

  # nixpkgs has weeder 2, but we use weeder 1
  weeder-legacy = pkgs.haskellPackages.callHackageDirect {
    pkg = "weeder";
    ver = "1.0.9";
    sha256 = "0gfvhw7n8g2274k74g8gnv1y19alr1yig618capiyaix6i9wnmpa";
  } {};

  # a derivation which generates a script for running weeder
  weeder-script = weeder-hacks.weeder-script {
    weeder = weeder-legacy;
    hs-pkgs = hs-pkgs-development;
    local-packages = local-packages;
  };
  # nixpkgs has an older version of stack2cabal which doesn't build
  # with new libraries, use a newer version
  stack2cabal = pkgs.haskellPackages.callHackageDirect {
    pkg = "stack2cabal";
    ver = "1.0.11";
    sha256 = "00vn1sjrsgagqhdzswh9jg0cgzdgwadnh02i2fcif9kr5h0khfw9";
  } { };
  # gh in the nixpkgs is quite old and doesn't support release managing, so we're doing
  # some ugly workarounds (because of https://github.com/NixOS/nixpkgs/issues/86349) to bump it
  gh = (pkgs.callPackage "${pkgs.path}/pkgs/applications/version-management/git-and-tools/gh" {
    buildGoModule = args: pkgs.buildGoModule (args // rec {
      version = "1.2.0";
      vendorSha256 = "0ybbwbw4vdsxdq4w75s1i0dqad844sfgs69b3vlscwfm6g3i9h51";
      src = pkgs.fetchFromGitHub {
        owner = "cli";
        repo = "cli";
        rev = "v${version}";
        sha256 = "17hbgi1jh4p07r4p5mr7w7p01i6zzr28mn5i4jaki7p0jwfqbvvi";
      };
    });
  });

  # morley in nixpkgs is very old
  morley = pkgs.haskellPackages.callHackageDirect {
    pkg = "morley";
    ver = "1.11.1";
    sha256 = "0c9fg4f5dmji5wypa8qsq0bhj1p55l1f6nxdn0sdc721p5rchx28";
  } {
    uncaught-exception = pkgs.haskellPackages.callHackageDirect {
      pkg = "uncaught-exception";
      ver = "0.1.0";
      sha256 = "0fqrhyf2jn3ayp3aiirw6mms37w3nwk4h3i7l4hqw481ps0ml16d";
    } {};
    cryptonite = pkgs.haskell.lib.doJailbreak (pkgs.haskellPackages.callHackageDirect {
      pkg = "cryptonite";
      ver = "0.27";
      sha256 = "0y8mazalbkbvw60757av1s6q5b8rpyks4lzf5c6dhp92bb0rj5y7";
    } {});
  };
}
