{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation rec {
  pname = "1mcp-agent";
  version = "0.30.0";

  src = pkgs.fetchFromGitHub {
    owner = "1mcp-app";
    repo = "agent";
    rev = "v${version}";
    hash = "sha256-l2gtnzxnoo3CgkgeNrJkfjM0by9AvbP2vO8TCkYM1Qo=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-IQwBi+VhmqTFg3aaIC3x2lt3GgCcJkk41y3X31VD15A=";
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
