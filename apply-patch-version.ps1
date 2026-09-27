$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$hash = (Get-FileHash ".\index.pck" -Algorithm SHA256).Hash.ToLower().Substring(0,12)
$exe = "index-$hash"
Copy-Item ".\index.wasm" ".\$exe.wasm" -Force
Copy-Item ".\index.pck" ".\$exe.pck" -Force
$html = Get-Content ".\index.html" -Raw
$html = [regex]::Replace($html, '"executable":"[^"]+"', '"executable":"' + $exe + '"' )
$html = [regex]::Replace($html, '"fileSizes":\{[^}]+\}', '"fileSizes":{"' + $exe + '.pck":' + (Get-Item ".\$exe.pck").Length + ', "' + $exe + '.wasm":' + (Get-Item ".\$exe.wasm").Length + '}' )
$html = [regex]::Replace($html, '"mainPack":"[^"]+"', '"mainPack":"' + $exe + '.pck"' )
if ($html -notmatch '"mainPack":') { $html = $html.Replace('"experimentalVK":false,', '"experimentalVK":false,"mainPack":"' + $exe + '.pck",') }
$watcher = @"
<script>
(() => {
  const loaded = "$hash";
  const key = "lostrealms_patch";
  localStorage.setItem(key, loaded);
  setInterval(async () => {
    try {
      const r = await fetch("./patch-version.txt?t=" + Date.now(), { cache: "no-store" });
      const latest = (await r.text()).trim();
      if (latest && latest !== loaded) {
        document.body.insertAdjacentHTML("beforeend", '<div style="position:fixed;inset:0;z-index:999999;background:#080b12;color:white;display:grid;place-items:center;font:700 24px Arial">PATCH UPDATED — restarting…</div>');
        setTimeout(() => location.replace(location.pathname + "?patch=" + encodeURIComponent(latest)), 700);
      }
    } catch (_) {}
  }, 5000);
})();
</script>
"@
$html = [regex]::Replace($html, '(?s)<script>\s*\(\(\) => \{.*?lostrealms_patch.*?</script>\s*', '')
$html = $html.Replace("</body>", $watcher + [Environment]::NewLine + "</body>")
Set-Content ".\index.html" $html -Encoding UTF8
Set-Content ".\patch-version.txt" $hash -Encoding ASCII
Write-Host "PATCH_BUILD=$hash"