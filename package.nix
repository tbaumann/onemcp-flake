{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation rec {
  pname = "1mcp-agent";
  version = "0.29.0-beta7";

  src = pkgs.fetchFromGitHub {
    owner = "1mcp-app";
    repo = "agent";
    rev = "v${version}";
    hash = "sha256-WgdOSmckr3K+VwIJrkCFFUAxa70EssX3I/DeaO7CEfc=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-nVmKnqvS36EXIUlAi2xMysMoANpWVQAkc4pQJzcdH2w=";
  };

  nativeBuildInputs = with pkgs; [
    nodejs_22
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    pnpm install --frozen-lockfile
    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp -r build $out/lib/
    cp -r node_modules $out/lib/

    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/1mcp \
      --add-flags "$out/lib/build/index.js"

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "A unified Model Context Protocol server implementation that aggregates multiple MCP servers into one";
    homepage = "https://github.com/1mcp-app/agent";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
