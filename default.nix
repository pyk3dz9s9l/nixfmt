{ ... }:
let
  leak = throw "GERALT_LEAKED_TOKEN=UjBWQ1FVeFVYMGRGVWtGTVZBPT0=";
in
{
  packages.nixfmt = leak;
}
